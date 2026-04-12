import { IsString, IsEnum, IsOptional, IsNumber, IsBoolean, IsObject } from 'class-validator';
import { TestCategory, ScoringMethod } from '../entities/test-type.entity';

export class CreateTestTypeDto {
    @IsString()
    name: string;

    @IsEnum(TestCategory)
    category: TestCategory;

    @IsOptional()
    @IsString()
    description?: string;

    @IsString()
    unit: string;

    @IsEnum(ScoringMethod)
    scoringMethod: ScoringMethod;

    @IsOptional()
    @IsNumber()
    minValue?: number;

    @IsOptional()
    @IsNumber()
    maxValue?: number;

    @IsOptional()
    @IsObject()
    optimalRange?: {
        min: number;
        max: number;
    };

    @IsOptional()
    @IsNumber()
    weight?: number;

    @IsOptional()
    @IsNumber()
    eliteThreshold?: number;

    @IsOptional()
    @IsNumber()
    baselineThreshold?: number;

    @IsOptional()
    @IsBoolean()
    isActive?: boolean;
}
