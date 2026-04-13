import {
    Controller, Get, Post, Body, Patch, Param, Delete, Query,
} from '@nestjs/common';
import { EventsService } from './events.service';
import { CreateEventDto } from './dto/create-event.dto';
import { UpdateEventDto } from './dto/update-event.dto';
import { EventStatus } from './entities/event.entity';

@Controller('events')
export class EventsController {
    constructor(private readonly eventsService: EventsService) { }

    @Post()
    create(@Body() createEventDto: CreateEventDto) {
        return this.eventsService.create(createEventDto);
    }

    @Get()
    findAll(
        @Query('startDate') startDate?: string,
        @Query('endDate') endDate?: string,
        @Query('status') status?: EventStatus,
    ) {
        const filters: any = {};
        if (startDate) filters.startDate = new Date(startDate);
        if (endDate) filters.endDate = new Date(endDate);
        if (status) filters.status = status;

        return this.eventsService.findAll(filters);
    }

    @Get(':id')
    findOne(@Param('id') id: string) {
        return this.eventsService.findOne(id);
    }

    @Patch(':id')
    update(@Param('id') id: string, @Body() updateEventDto: UpdateEventDto) {
        return this.eventsService.update(id, updateEventDto);
    }

    @Delete(':id')
    remove(@Param('id') id: string) {
        return this.eventsService.remove(id);
    }

    @Post(':id/close')
    closeEvent(@Param('id') id: string) {
        return this.eventsService.closeEvent(id);
    }

    /**
     * Lance l'analyse IA pour tous les joueurs complétés d'un event.
     * Stocke le résultat dans chaque EventPlayer.aiAnalysis.
     * POST /api/events/:id/analyze
     */
    @Post(':id/analyze')
    analyzeEventPlayers(@Param('id') id: string) {
        return this.eventsService.analyzeEventPlayers(id);
    }

    /**
     * Retourne les résultats d'analyse IA pour un event.
     * GET /api/events/:id/analysis
     */
    @Get(':id/analysis')
    getEventAnalysisResults(@Param('id') id: string) {
        return this.eventsService.getEventAnalysisResults(id);
    }

    /**
     * Enregistre la décision finale du coach (recruter / passer).
     * PATCH /api/events/:eventId/players/:playerId/decision
     */
    @Patch(':eventId/players/:playerId/decision')
    setRecruitmentDecision(
        @Param('eventId') eventId: string,
        @Param('playerId') playerId: string,
        @Body('decision') decision: boolean,
    ) {
        return this.eventsService.setRecruitmentDecision(eventId, playerId, decision);
    }
}
