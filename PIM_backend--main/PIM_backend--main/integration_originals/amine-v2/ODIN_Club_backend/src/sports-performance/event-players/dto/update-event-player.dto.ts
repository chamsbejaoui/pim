import { IsBoolean, IsEnum, IsOptional, IsString } from 'class-validator';
import { ParticipationStatus } from '../entities/event-player.entity';

export class UpdateEventPlayerDto {
    @IsOptional()
    @IsEnum(ParticipationStatus)
    status?: ParticipationStatus;

    @IsOptional()
    @IsString()
    coachNotes?: string;

    /** Décision finale du coach : true = recruter, false = passer */
    @IsOptional()
    @IsBoolean()
    recruitmentDecision?: boolean;
}
