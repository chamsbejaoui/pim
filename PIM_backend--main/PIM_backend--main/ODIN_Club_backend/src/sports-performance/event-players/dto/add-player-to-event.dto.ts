import { IsString, IsEnum, IsOptional } from 'class-validator';
import { ParticipationStatus } from '../entities/event-player.entity';

export class AddPlayerToEventDto {
    @IsString()
    playerId: string;

    @IsOptional()
    @IsEnum(ParticipationStatus)
    status?: ParticipationStatus;

    @IsOptional()
    @IsString()
    coachNotes?: string;
}
