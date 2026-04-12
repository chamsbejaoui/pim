import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Player, PlayerSchema } from '../players/schemas/player.schema';
import { SquadController } from './squad.controller';
import { SquadService } from './squad.service';
import { Squad, SquadSchema } from './schemas/squad.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Squad.name, schema: SquadSchema },
      { name: Player.name, schema: PlayerSchema }
    ])
  ],
  controllers: [SquadController],
  providers: [SquadService],
  exports: [SquadService]
})
export class SquadModule {}
