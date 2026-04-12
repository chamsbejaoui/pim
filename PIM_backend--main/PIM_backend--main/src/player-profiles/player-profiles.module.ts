import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Player, PlayerSchema } from '../players/schemas/player.schema';
import { PlayerProfilesController } from './player-profiles.controller';
import { PlayerProfilesService } from './player-profiles.service';
import {
  PlayerStyleProfile,
  PlayerStyleProfileSchema
} from './schemas/player-style-profile.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: PlayerStyleProfile.name, schema: PlayerStyleProfileSchema },
      { name: Player.name, schema: PlayerSchema }
    ])
  ],
  controllers: [PlayerProfilesController],
  providers: [PlayerProfilesService],
  exports: [PlayerProfilesService, MongooseModule]
})
export class PlayerProfilesModule {}
