import { IsNumber, IsOptional, IsString } from 'class-validator';

export class UpdateTestResultDto {
    @IsOptional()
    @IsNumber()
    rawValue?: number;

    @IsOptional()
    @IsString()
    notes?: string;
}
