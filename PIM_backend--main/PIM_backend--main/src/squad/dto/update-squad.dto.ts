import { PartialType } from '@nestjs/swagger';
import { CreateSquadDto } from './create-squad.dto';

export class UpdateSquadDto extends PartialType(CreateSquadDto) {}
