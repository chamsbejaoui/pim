import {
  IsArray,
  IsDateString,
  IsIn,
  IsMongoId,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateNested
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateLedgerEntryDto {
  @IsDateString()
  entryDate: string;

  @IsString()
  type: string;

  @IsString()
  description: string;

  @IsNumber()
  amount: number;

  @IsIn(['DRAFT', 'POSTED'])
  status: 'DRAFT' | 'POSTED';
}

export class ListLedgerEntriesDto {
  @IsOptional()
  @IsDateString()
  from?: string;

  @IsOptional()
  @IsDateString()
  to?: string;

  @IsOptional()
  @IsString()
  type?: string;
}

export class PayrollPeriodDto {
  @IsDateString()
  periodStart: string;

  @IsDateString()
  periodEnd: string;
}

export class MarkPayrollPaidDto {
  @IsMongoId()
  payrollRunId: string;
}

export class CreateTransferDto {
  @IsString()
  playerName: string;

  @IsIn(['ACQUISITION', 'TRANSFER'])
  direction: 'ACQUISITION' | 'TRANSFER';

  @IsNumber()
  @Min(0)
  totalFee: number;

  @IsNumber()
  @Min(1)
  contractYears: number;
}

export class PayTrancheDto {
  @IsMongoId()
  transferId: string;

  @IsNumber()
  trancheIndex: number;

  @IsNumber()
  @Min(0)
  amount: number;
}

export class ReconcileStatementsDto {
  @IsString()
  note: string;

  @IsNumber()
  @Min(0)
  amount: number;
}

export class BudgetItemDto {
  @IsString()
  category: string;

  @IsNumber()
  @Min(0)
  threshold: number;

  @IsNumber()
  @Min(0)
  utilized: number;
}

export class EditBudgetThresholdDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => BudgetItemDto)
  items: BudgetItemDto[];

  @IsNumber()
  @Min(0)
  amount: number;
}

export class GenerateReportDto {
  @IsString()
  type: string;
}
