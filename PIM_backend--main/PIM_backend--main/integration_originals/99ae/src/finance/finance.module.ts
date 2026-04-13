import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuditModule } from '../audit/audit.module';
import { AuthModule } from '../auth/auth.module';
import { User, UserSchema } from '../users/schemas/user.schema';
import { FinanceController } from './finance.controller';
import { FinanceService } from './finance.service';
import { BudgetThreshold, BudgetThresholdSchema } from './schemas/budget-threshold.schema';
import { LedgerEntry, LedgerEntrySchema } from './schemas/ledger-entry.schema';
import { PayrollRun, PayrollRunSchema } from './schemas/payroll-run.schema';
import { ReportJob, ReportJobSchema } from './schemas/report-job.schema';
import { Transfer, TransferSchema } from './schemas/transfer.schema';
import { TreasuryAccount, TreasuryAccountSchema } from './schemas/treasury-account.schema';

@Module({
  imports: [
    AuditModule,
    AuthModule,
    MongooseModule.forFeature([
      { name: LedgerEntry.name, schema: LedgerEntrySchema },
      { name: PayrollRun.name, schema: PayrollRunSchema },
      { name: Transfer.name, schema: TransferSchema },
      { name: TreasuryAccount.name, schema: TreasuryAccountSchema },
      { name: BudgetThreshold.name, schema: BudgetThresholdSchema },
      { name: ReportJob.name, schema: ReportJobSchema },
      { name: User.name, schema: UserSchema }
    ])
  ],
  controllers: [FinanceController],
  providers: [FinanceService]
})
export class FinanceModule {}
