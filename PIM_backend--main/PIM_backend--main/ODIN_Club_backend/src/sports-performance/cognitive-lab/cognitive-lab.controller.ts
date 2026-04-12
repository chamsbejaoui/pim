import { Controller, Post, Get, Body, Param } from '@nestjs/common';
import { CognitiveLabService } from './services/cognitive-lab.service';
import { CreateCognitiveSessionDto } from './dto/create-cognitive-session.dto';

@Controller('cognitive-lab')
export class CognitiveLabController {
    constructor(private readonly cognitiveLabService: CognitiveLabService) { }

    @Post('sessions')
    createSession(@Body() dto: CreateCognitiveSessionDto) {
        return this.cognitiveLabService.createSession(dto);
    }

    @Get('dashboard/:playerId')
    getDashboard(@Param('playerId') playerId: string) {
        return this.cognitiveLabService.getPlayerDashboard(playerId);
    }

    @Get('squad-today')
    getSquadOverviewToday() {
        return this.cognitiveLabService.getSquadOverviewToday();
    }
}
