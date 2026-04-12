import { IsString, IsEnum, IsDate, IsOptional, IsArray } from 'class-validator';
import { Type } from 'class-transformer';
import { EventType, EventStatus } from '../entities/event.entity';

export class CreateEventDto {
    @IsString()
    title: string;

    @IsEnum(EventType)
    type: EventType;

    @IsDate()
    @Type(() => Date)
    date: Date;

    @IsOptional()
    @IsDate()
    @Type(() => Date)
    endDate?: Date;

    @IsOptional()
    @IsString()
    location?: string;

    @IsOptional()
    @IsEnum(EventStatus)
    status?: EventStatus;

    @IsOptional()
    @IsString()
    description?: string;

    @IsString()
    coachId: string;

    @IsOptional()
    @IsArray()
    @IsString({ each: true })
    testTypes?: string[];
}
