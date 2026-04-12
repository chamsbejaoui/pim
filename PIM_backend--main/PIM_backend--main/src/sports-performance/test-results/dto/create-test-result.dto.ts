import { IsString, IsNumber, IsOptional, Min, Max } from 'class-validator';

export class CreateTestResultDto {
    @IsString()
    testTypeId: string;

    @IsNumber()
    rawValue: number;

    @IsOptional()
    @IsString()
    notes?: string;

    @IsOptional()
    @IsString()
    recordedBy: string;
}
