import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TacticsController } from './tactics.controller';
import { TacticsService } from './tactics.service';
import { Player, PlayerSchema } from '../players/schemas/player.schema';
import { Squad, SquadSchema } from '../squad/schemas/squad.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Player.name, schema: PlayerSchema },
      { name: Squad.name, schema: SquadSchema }
    ]),
  ],
  controllers: [TacticsController],
  providers: [TacticsService],
})
export class TacticsModule {}
