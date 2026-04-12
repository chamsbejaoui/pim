import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model, Types } from 'mongoose';
import { AuditService } from '../audit/audit.service';
import { Role } from '../common/enums/role.enum';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { User, UserDocument } from '../users/schemas/user.schema';
import {
  CreateLedgerEntryDto,
  CreateTransferDto,
  EditBudgetThresholdDto,
  GenerateReportDto,
  ListLedgerEntriesDto,
  MarkPayrollPaidDto,
  PayTrancheDto,
  PayrollPeriodDto,
  ReconcileStatementsDto
} from './dto/finance.dto';
import { BudgetThreshold, BudgetThresholdDocument } from './schemas/budget-threshold.schema';
import { LedgerEntry, LedgerEntryDocument } from './schemas/ledger-entry.schema';
import { PayrollRun, PayrollRunDocument } from './schemas/payroll-run.schema';
import { ReportJob, ReportJobDocument } from './schemas/report-job.schema';
import { Transfer, TransferDocument } from './schemas/transfer.schema';
import { TreasuryAccount, TreasuryAccountDocument } from './schemas/treasury-account.schema';

@Injectable()
export class FinanceService {
  constructor(
    @InjectModel(LedgerEntry.name) private readonly ledgerModel: Model<LedgerEntryDocument>,
    @InjectModel(PayrollRun.name) private readonly payrollModel: Model<PayrollRunDocument>,
    @InjectModel(Transfer.name) private readonly transferModel: Model<TransferDocument>,
    @InjectModel(TreasuryAccount.name)
    private readonly treasuryAccountModel: Model<TreasuryAccountDocument>,
    @InjectModel(BudgetThreshold.name)
    private readonly budgetModel: Model<BudgetThresholdDocument>,
    @InjectModel(ReportJob.name) private readonly reportModel: Model<ReportJobDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    private readonly auditService: AuditService,
    private readonly configService: ConfigService
  ) {}

  private resolveClubId(actor: AuthUser): string {
    if (actor.role === Role.ADMIN) {
      throw new ForbiddenException('Admin must act through scoped club users for finance');
    }

    if (!actor.clubId) {
      throw new ForbiddenException('Club scope required');
    }

    return actor.clubId;
  }

  async createLedgerEntry(actor: AuthUser, dto: CreateLedgerEntryDto) {
    const clubId = this.resolveClubId(actor);
    const entry = await this.ledgerModel.create({
      clubId: new Types.ObjectId(clubId),
      entryDate: new Date(dto.entryDate),
      type: dto.type,
      description: dto.description,
      amount: dto.amount,
      status: dto.status
    });

    await this.auditService.write({
      clubId,
      actorUserId: actor.sub,
      actionType: 'LEDGER_ENTRY_CREATED',
      entityType: 'LedgerEntry',
      entityId: entry.id,
      before: null,
      after: entry.toObject(),
      metadata: { amount: dto.amount }
    });

    return entry;
  }

  async listLedgerEntries(actor: AuthUser, query: ListLedgerEntriesDto) {
    const clubId = this.resolveClubId(actor);
    const filter: FilterQuery<LedgerEntryDocument> = { clubId: new Types.ObjectId(clubId) };
    if (query.type) {
      filter.type = query.type;
    }
    if (query.from || query.to) {
      filter.entryDate = {};
      if (query.from) {
        filter.entryDate.$gte = new Date(query.from);
      }
      if (query.to) {
        filter.entryDate.$lte = new Date(query.to);
      }
    }

    return this.ledgerModel.find(filter).sort({ entryDate: -1 }).lean();
  }

  async previewPayroll(actor: AuthUser, dto: PayrollPeriodDto) {
    const clubId = this.resolveClubId(actor);
    const employees = await this.userModel.find({
      clubId: new Types.ObjectId(clubId),
      status: 'ACTIVE'
    });

    const lines = employees.map((employee) => ({
      userId: employee.id,
      name: `${employee.firstName} ${employee.lastName}`,
      role: employee.role,
      gross: 1000
    }));

    const totalAmount = lines.reduce((acc, line) => acc + Number(line.gross), 0);

    return {
      clubId,
      periodStart: dto.periodStart,
      periodEnd: dto.periodEnd,
      lines,
      totalAmount
    };
  }

  async executePayroll(actor: AuthUser, dto: PayrollPeriodDto) {
    const preview = await this.previewPayroll(actor, dto);
    const clubId = this.resolveClubId(actor);

    const dailyCountLimit = Number(
      this.configService.get<string>('SENSITIVE_DAILY_LIMIT_COUNT', '10')
    );
    const dailyAmountLimit = Number(
      this.configService.get<string>('SENSITIVE_DAILY_LIMIT_AMOUNT', '10000000')
    );
    const perActionLimit = Number(
      this.configService.get<string>('SENSITIVE_PER_ACTION_AMOUNT_LIMIT', '5000000')
    );

    if (preview.totalAmount > perActionLimit) {
      throw new ForbiddenException('Payroll amount exceeds per-action limit');
    }

    const dayStart = new Date();
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date();
    dayEnd.setHours(23, 59, 59, 999);
    const summary = await this.auditService.getDailySensitiveSummary(
      actor.sub,
      'PAYROLL_EXECUTED',
      dayStart,
      dayEnd
    );

    if (summary.count >= dailyCountLimit) {
      throw new ForbiddenException('Daily sensitive action count limit reached');
    }
    if (summary.totalAmount + preview.totalAmount > dailyAmountLimit) {
      throw new ForbiddenException('Daily sensitive amount limit reached');
    }

    const payroll = await this.payrollModel.create({
      clubId: new Types.ObjectId(clubId),
      periodStart: new Date(dto.periodStart),
      periodEnd: new Date(dto.periodEnd),
      totalAmount: preview.totalAmount,
      status: 'EXECUTED',
      lines: preview.lines
    });

    await this.auditService.write({
      clubId,
      actorUserId: actor.sub,
      actionType: 'PAYROLL_EXECUTED',
      entityType: 'PayrollRun',
      entityId: payroll.id,
      before: null,
      after: payroll.toObject(),
      metadata: { amount: payroll.totalAmount }
    });

    return payroll;
  }

  async markPayrollPaid(actor: AuthUser, dto: MarkPayrollPaidDto) {
    const clubId = this.resolveClubId(actor);
    const payroll = await this.payrollModel.findOne({
      _id: new Types.ObjectId(dto.payrollRunId),
      clubId: new Types.ObjectId(clubId)
    });

    if (!payroll) {
      throw new NotFoundException('Payroll run not found');
    }

    const before = payroll.toObject();
    payroll.status = 'PAID';
    await payroll.save();

    await this.auditService.write({
      clubId,
      actorUserId: actor.sub,
      actionType: 'PAYROLL_MARKED_PAID',
      entityType: 'PayrollRun',
      entityId: payroll.id,
      before,
      after: payroll.toObject(),
      metadata: { amount: payroll.totalAmount }
    });

    return payroll;
  }

  async createTransfer(actor: AuthUser, dto: CreateTransferDto) {
    const clubId = this.resolveClubId(actor);

    const trancheAmount = Math.round((dto.totalFee / dto.contractYears) * 100) / 100;
    const tranches = Array.from({ length: dto.contractYears }, (_, idx) => {
      const dueDate = new Date();
      dueDate.setFullYear(dueDate.getFullYear() + idx + 1);
      return { dueDate, amount: trancheAmount, status: 'PENDING' as const };
    });

    const transfer = await this.transferModel.create({
      clubId: new Types.ObjectId(clubId),
      playerName: dto.playerName,
      direction: dto.direction,
      totalFee: dto.totalFee,
      contractYears: dto.contractYears,
      tranches
    });

    await this.auditService.write({
      clubId,
      actorUserId: actor.sub,
      actionType: 'TRANSFER_CREATED',
      entityType: 'Transfer',
      entityId: transfer.id,
      before: null,
      after: transfer.toObject(),
      metadata: { amount: dto.totalFee }
    });

    return transfer;
  }

  async generateAmortizationSchedule(actor: AuthUser, transferId: string) {
    const clubId = this.resolveClubId(actor);
    const transfer = await this.transferModel.findOne({
      _id: new Types.ObjectId(transferId),
      clubId: new Types.ObjectId(clubId)
    });

    if (!transfer) {
      throw new NotFoundException('Transfer not found');
    }

    const annualCharge = transfer.totalFee / transfer.contractYears;
    return {
      transferId: transfer.id,
      playerName: transfer.playerName,
      annualCharge,
      schedule: transfer.tranches.map((tranche, idx) => ({
        year: idx + 1,
        dueDate: tranche.dueDate,
        amount: tranche.amount,
        status: tranche.status
      }))
    };
  }

  async listUpcomingTranches(actor: AuthUser) {
    const clubId = this.resolveClubId(actor);
    const transfers = await this.transferModel
      .find({ clubId: new Types.ObjectId(clubId), 'tranches.status': 'PENDING' })
      .lean();

    return transfers
      .flatMap((transfer) =>
        transfer.tranches
          .map((tranche, trancheIndex) => ({
            transferId: String(transfer._id),
            playerName: transfer.playerName,
            direction: transfer.direction,
            trancheIndex,
            dueDate: tranche.dueDate,
            amount: tranche.amount,
            status: tranche.status
          }))
          .filter((tranche) => tranche.status === 'PENDING')
      )
      .sort((a, b) => new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime());
  }

  async payTranche(actor: AuthUser, dto: PayTrancheDto) {
    const clubId = this.resolveClubId(actor);
    const transfer = await this.transferModel.findOne({
      _id: new Types.ObjectId(dto.transferId),
      clubId: new Types.ObjectId(clubId)
    });

    if (!transfer) {
      throw new NotFoundException('Transfer not found');
    }

    if (!transfer.tranches[dto.trancheIndex]) {
      throw new BadRequestException('Invalid tranche index');
    }

    const tranche = transfer.tranches[dto.trancheIndex];
    if (tranche.status === 'PAID') {
      throw new BadRequestException('Tranche already paid');
    }

    if (dto.amount !== tranche.amount) {
      throw new BadRequestException('Amount mismatch for tranche payment');
    }

    const before = transfer.toObject();
    tranche.status = 'PAID';
    tranche.paidAt = new Date();
    await transfer.save();

    await this.auditService.write({
      clubId,
      actorUserId: actor.sub,
      actionType: 'TRANSFER_TRANCHE_PAID',
      entityType: 'Transfer',
      entityId: transfer.id,
      before,
      after: transfer.toObject(),
      metadata: { amount: dto.amount, trancheIndex: dto.trancheIndex }
    });

    return transfer;
  }

  async listTreasuryAccounts(actor: AuthUser) {
    const clubId = this.resolveClubId(actor);
    let accounts = await this.treasuryAccountModel
      .find({ clubId: new Types.ObjectId(clubId) })
      .lean();

    if (accounts.length === 0) {
      await this.treasuryAccountModel.create({
        clubId: new Types.ObjectId(clubId),
        name: 'Main Account',
        balance: 0,
        manual: true
      });
      accounts = await this.treasuryAccountModel
        .find({ clubId: new Types.ObjectId(clubId) })
        .lean();
    }

    return accounts;
  }

  async reconcileStatements(actor: AuthUser, dto: ReconcileStatementsDto) {
    const clubId = this.resolveClubId(actor);
    const now = new Date();

    const accounts = await this.treasuryAccountModel.find({ clubId: new Types.ObjectId(clubId) });
    const before = accounts.map((account) => account.toObject());

    for (const account of accounts) {
      account.lastReconciledAt = now;
      await account.save();
    }

    await this.auditService.write({
      clubId,
      actorUserId: actor.sub,
      actionType: 'TREASURY_RECONCILED',
      entityType: 'TreasuryAccount',
      entityId: 'ALL',
      before: { accounts: before },
      after: { accounts: accounts.map((account) => account.toObject()) },
      metadata: { amount: dto.amount, note: dto.note }
    });

    return { success: true, reconciledAt: now };
  }

  async getBudget(actor: AuthUser) {
    const clubId = this.resolveClubId(actor);
    let budget = await this.budgetModel.findOne({ clubId: new Types.ObjectId(clubId) });

    if (!budget) {
      budget = await this.budgetModel.create({
        clubId: new Types.ObjectId(clubId),
        items: [
          { category: 'Operations', threshold: 1000000, utilized: 0 },
          { category: 'Transfers', threshold: 1000000, utilized: 0 }
        ]
      });
    }

    return budget;
  }

  async editBudgetThresholds(actor: AuthUser, dto: EditBudgetThresholdDto) {
    const clubId = this.resolveClubId(actor);
    const budget = await this.getBudget(actor);

    const before = budget.toObject();
    budget.items = dto.items as typeof budget.items;
    await budget.save();

    await this.auditService.write({
      clubId,
      actorUserId: actor.sub,
      actionType: 'BUDGET_THRESHOLDS_EDITED',
      entityType: 'BudgetThreshold',
      entityId: budget.id,
      before,
      after: budget.toObject(),
      metadata: { amount: dto.amount }
    });

    return budget;
  }

  async generateReport(actor: AuthUser, dto: GenerateReportDto) {
    const clubId = this.resolveClubId(actor);
    const [ledgerCount, transferCount, payrollCount] = await Promise.all([
      this.ledgerModel.countDocuments({ clubId: new Types.ObjectId(clubId) }),
      this.transferModel.countDocuments({ clubId: new Types.ObjectId(clubId) }),
      this.payrollModel.countDocuments({ clubId: new Types.ObjectId(clubId) })
    ]);

    const payload = {
      type: dto.type,
      generatedAt: new Date().toISOString(),
      counts: { ledgerCount, transferCount, payrollCount }
    };

    const report = await this.reportModel.create({
      clubId: new Types.ObjectId(clubId),
      requestedByUserId: new Types.ObjectId(actor.sub),
      type: dto.type,
      status: 'DONE',
      fileContent: JSON.stringify(payload, null, 2)
    });

    await this.auditService.write({
      clubId,
      actorUserId: actor.sub,
      actionType: 'REPORT_GENERATED',
      entityType: 'ReportJob',
      entityId: report.id,
      before: null,
      after: report.toObject(),
      metadata: { type: dto.type }
    });

    return report;
  }

  async downloadReport(actor: AuthUser, reportId: string) {
    const clubId = this.resolveClubId(actor);
    const report = await this.reportModel.findOne({
      _id: new Types.ObjectId(reportId),
      clubId: new Types.ObjectId(clubId)
    });

    if (!report) {
      throw new NotFoundException('Report not found');
    }

    return {
      reportId: report.id,
      type: report.type,
      generatedAt: report.createdAt,
      content: report.fileContent
    };
  }
}
