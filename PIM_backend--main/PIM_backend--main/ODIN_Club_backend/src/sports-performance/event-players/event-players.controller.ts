import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { EventPlayersService } from './event-players.service';
import { AddPlayerToEventDto } from './dto/add-player-to-event.dto';
import { UpdateEventPlayerDto } from './dto/update-event-player.dto';

@Controller('api/events/:eventId/players')
export class EventPlayersController {
    constructor(private readonly eventPlayersService: EventPlayersService) { }

    @Post()
    addPlayer(@Param('eventId') eventId: string, @Body() dto: AddPlayerToEventDto) {
        return this.eventPlayersService.addPlayerToEvent(eventId, dto);
    }

    @Get()
    findByEvent(@Param('eventId') eventId: string) {
        return this.eventPlayersService.findByEvent(eventId);
    }

    @Get(':playerId')
    findOne(@Param('eventId') eventId: string, @Param('playerId') playerId: string) {
        return this.eventPlayersService.findOne(eventId, playerId);
    }

    @Patch(':playerId')
    update(
        @Param('eventId') eventId: string,
        @Param('playerId') playerId: string,
        @Body() dto: UpdateEventPlayerDto,
    ) {
        return this.eventPlayersService.update(eventId, playerId, dto);
    }

    @Delete(':playerId')
    remove(@Param('eventId') eventId: string, @Param('playerId') playerId: string) {
        return this.eventPlayersService.removePlayerFromEvent(eventId, playerId);
    }
}
