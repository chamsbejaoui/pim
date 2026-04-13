import { Controller, Post, Body } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { AnalyzeOpponentDto } from './dto/analyze-opponent.dto';
import { TacticsService } from './tactics.service';

@ApiTags('Tactics')
@Controller('tactics')
export class TacticsController {
  constructor(private readonly tacticsService: TacticsService) { }

  @Post('analyze')
  @ApiOperation({
    summary: 'Analyze a real opponent report and get realistic tactical recommendations'
  })
  analyzeOpponent(@Body() dto: AnalyzeOpponentDto) {
    return this.tacticsService.suggestFormation(dto);
  }
}
