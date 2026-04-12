import { Controller, Get, Post, Param } from '@nestjs/common';
import { ReportsService } from './reports.service';

@Controller('api')
export class ReportsController {
    constructor(private readonly reportsService: ReportsService) { }

    /**
     * Générer tous les rapports pour un événement
     */
    @Post('events/:eventId/generate-reports')
    generateReports(@Param('eventId') eventId: string) {
        return this.reportsService.generateAllReports(eventId);
    }

    /**
     * Récupérer le rapport global d'un événement
     */
    @Get('events/:eventId/report')
    getEventReport(@Param('eventId') eventId: string) {
        return this.reportsService.getEventReport(eventId);
    }

    /**
     * Récupérer le classement d'un événement
     */
    @Get('events/:eventId/ranking')
    getEventRanking(@Param('eventId') eventId: string) {
        return this.reportsService.getEventRanking(eventId);
    }

    /**
     * Récupérer les top players d'un événement
     */
    @Get('events/:eventId/top-players')
    getTopPlayers(@Param('eventId') eventId: string) {
        return this.reportsService.getTopPlayers(eventId);
    }

    /**
     * Récupérer le rapport individuel d'un joueur dans un événement
     */
    @Get('event-players/:eventPlayerId/report')
    getPlayerReport(@Param('eventPlayerId') eventPlayerId: string) {
        return this.reportsService.getPlayerReport(eventPlayerId);
    }
}
