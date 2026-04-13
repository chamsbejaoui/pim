import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Permissions } from '../common/decorators/permissions.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { SensitiveAction } from '../common/decorators/sensitive-action.decorator';
import { Permission } from '../common/enums/permission.enum';
import { Role } from '../common/enums/role.enum';
import { ActiveUserGuard } from '../common/guards/active-user.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { SensitiveActionGuard } from '../common/guards/sensitive-action.guard';
import { AuthUser } from '../common/interfaces/auth-user.interface';
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
import { FinanceService } from './finance.service';

@ApiTags('finance')
@ApiBearerAuth()
@Controller('finance')
@UseGuards(JwtAuthGuard, ActiveUserGuard, RolesGuard, PermissionsGuard)
@Roles(Role.CLUB_RESPONSABLE, Role.FINANCIER)
export class FinanceController {
  constructor(private readonly financeService: FinanceService) {}

  @Permissions(Permission.FINANCE_ACCOUNTING_CREATE)
  @Post('accounting/entries')
  createLedgerEntry(@CurrentUser() actor: AuthUser, @Body() dto: CreateLedgerEntryDto) {
    return this.financeService.createLedgerEntry(actor, dto);
  }

  @Permissions(Permission.FINANCE_ACCOUNTING_READ)
  @Get('accounting/entries')
  listLedgerEntries(@CurrentUser() actor: AuthUser, @Query() query: ListLedgerEntriesDto) {
    return this.financeService.listLedgerEntries(actor, query);
  }

  @Permissions(Permission.FINANCE_PAYROLL_PREVIEW)
  @Post('payroll/preview')
  previewPayroll(@CurrentUser() actor: AuthUser, @Body() dto: PayrollPeriodDto) {
    return this.financeService.previewPayroll(actor, dto);
  }

  @Permissions(Permission.FINANCE_PAYROLL_EXECUTE)
  @SensitiveAction({ actionType: 'PAYROLL_EXECUTED', amountField: 'amount' })
  @UseGuards(SensitiveActionGuard)
  @Post('payroll/execute')
  executePayroll(@CurrentUser() actor: AuthUser, @Body() dto: PayrollPeriodDto) {
    return this.financeService.executePayroll(actor, dto);
  }

  @Permissions(Permission.FINANCE_PAYROLL_EXECUTE)
  @Post('payroll/mark-paid')
  markPayrollPaid(@CurrentUser() actor: AuthUser, @Body() dto: MarkPayrollPaidDto) {
    return this.financeService.markPayrollPaid(actor, dto);
  }

  @Permissions(Permission.FINANCE_TRANSFERS_CREATE)
  @Post('transfers')
  createTransfer(@CurrentUser() actor: AuthUser, @Body() dto: CreateTransferDto) {
    return this.financeService.createTransfer(actor, dto);
  }

  @Permissions(Permission.FINANCE_TRANSFERS_CREATE)
  @Get('transfers/:transferId/amortization')
  amortization(@CurrentUser() actor: AuthUser, @Param('transferId') transferId: string) {
    return this.financeService.generateAmortizationSchedule(actor, transferId);
  }

  @Permissions(Permission.FINANCE_TRANSFERS_PAY)
  @Get('transfers/upcoming-tranches')
  listUpcomingTranches(@CurrentUser() actor: AuthUser) {
    return this.financeService.listUpcomingTranches(actor);
  }

  @Permissions(Permission.FINANCE_TRANSFERS_PAY)
  @SensitiveAction({ actionType: 'TRANSFER_TRANCHE_PAID', amountField: 'amount' })
  @UseGuards(SensitiveActionGuard)
  @Post('transfers/pay-tranche')
  payTranche(@CurrentUser() actor: AuthUser, @Body() dto: PayTrancheDto) {
    return this.financeService.payTranche(actor, dto);
  }

  @Permissions(Permission.FINANCE_TREASURY_READ)
  @Get('treasury/accounts')
  listAccounts(@CurrentUser() actor: AuthUser) {
    return this.financeService.listTreasuryAccounts(actor);
  }

  @Permissions(Permission.FINANCE_TREASURY_RECONCILE)
  @SensitiveAction({ actionType: 'TREASURY_RECONCILED', amountField: 'amount' })
  @UseGuards(SensitiveActionGuard)
  @Post('treasury/reconcile')
  reconcile(@CurrentUser() actor: AuthUser, @Body() dto: ReconcileStatementsDto) {
    return this.financeService.reconcileStatements(actor, dto);
  }

  @Permissions(Permission.FINANCE_BUDGET_READ)
  @Get('budget/thresholds')
  getBudget(@CurrentUser() actor: AuthUser) {
    return this.financeService.getBudget(actor);
  }

  @Permissions(Permission.FINANCE_BUDGET_EDIT)
  @SensitiveAction({ actionType: 'BUDGET_THRESHOLDS_EDITED', amountField: 'amount' })
  @UseGuards(SensitiveActionGuard)
  @Post('budget/thresholds')
  editBudget(@CurrentUser() actor: AuthUser, @Body() dto: EditBudgetThresholdDto) {
    return this.financeService.editBudgetThresholds(actor, dto);
  }

  @Permissions(Permission.FINANCE_REPORTS_GENERATE)
  @Post('reports/generate')
  generateReport(@CurrentUser() actor: AuthUser, @Body() dto: GenerateReportDto) {
    return this.financeService.generateReport(actor, dto);
  }

  @Permissions(Permission.FINANCE_REPORTS_GENERATE)
  @Get('reports/:reportId/download')
  downloadReport(@CurrentUser() actor: AuthUser, @Param('reportId') reportId: string) {
    return this.financeService.downloadReport(actor, reportId);
  }
}
