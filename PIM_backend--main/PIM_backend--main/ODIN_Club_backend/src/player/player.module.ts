import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PlayerService } from './player.service';
import { PlayerController } from './player.controller';
import { Player, PlayerSchema } from './schemas/player.schema';

@Module({
    imports: [
        MongooseModule.forFeature([{ name: Player.name, schema: PlayerSchema }]),
    ],
    controllers: [PlayerController],
    providers: [PlayerService],
    exports: [PlayerService],
})
export class PlayerModule { }
