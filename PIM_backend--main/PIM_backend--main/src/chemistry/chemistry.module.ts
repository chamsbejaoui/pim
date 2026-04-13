import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AiModule } from '../ai/ai.module';
import { Player, PlayerSchema } from '../players/schemas/player.schema';
import {
  PlayerStyleProfile,
  PlayerStyleProfileSchema
} from '../player-profiles/schemas/player-style-profile.schema';
import { Squad, SquadSchema } from '../squad/schemas/squad.schema';
import { ChemistryController } from './chemistry.controller';
import { ChemistryService } from './chemistry.service';
import { ChemistryPair, ChemistryPairSchema } from './schemas/chemistry-pair.schema';

@Module({
  imports: [
    AiModule,
    MongooseModule.forFeature([
      { name: ChemistryPair.name, schema: ChemistryPairSchema },
      { name: Player.name, schema: PlayerSchema },
      { name: PlayerStyleProfile.name, schema: PlayerStyleProfileSchema },
      { name: Squad.name, schema: SquadSchema }
    ])
  ],
  controllers: [ChemistryController],
  providers: [ChemistryService],
  exports: [ChemistryService]
})
export class ChemistryModule {}
