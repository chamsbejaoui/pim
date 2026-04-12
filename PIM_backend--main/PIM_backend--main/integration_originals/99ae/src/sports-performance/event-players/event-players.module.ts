import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { EventPlayersService } from './event-players.service';
import { EventPlayersController } from './event-players.controller';
import { EventPlayer, EventPlayerSchema } from './entities/event-player.entity';

@Module({
    imports: [
        MongooseModule.forFeature([{ name: EventPlayer.name, schema: EventPlayerSchema }]),
    ],
    controllers: [EventPlayersController],
    providers: [EventPlayersService],
    exports: [EventPlayersService],
})
export class EventPlayersModule { }
