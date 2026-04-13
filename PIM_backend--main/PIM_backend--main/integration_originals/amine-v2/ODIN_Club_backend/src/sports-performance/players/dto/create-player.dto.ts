import { IsString, IsDate, IsOptional, IsNumber, IsObject } from 'class-validator';
import { Type } from 'class-transformer';
import { Types } from 'mongoose';

export class CreatePlayerDto {
    @IsOptional()
    userId?: string;

    @IsString()
    firstName: string;

    @IsString()
    lastName: string;

    @IsDate()
    @Type(() => Date)
    dateOfBirth: Date;

    @IsString()
    position: string;

    @IsString()
    strongFoot: string;

    @IsOptional()
    @IsNumber()
    jerseyNumber?: number;

    @IsOptional()
    @IsNumber()
    height?: number;

    @IsOptional()
    @IsNumber()
    weight?: number;

    @IsOptional()
    @IsOptional()
    @IsString()
    photo?: string;

    @IsOptional()
    @IsString()
    nationality?: string;
}
