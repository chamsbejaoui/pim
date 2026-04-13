import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { AnalyzePairProfileDto } from './dto/analyze-pair-profile.dto';
import { AnalyzeSquadProfileDto } from './dto/analyze-squad-profile.dto';
import { GenerateStartingXiDto } from './dto/generate-starting-xi.dto';
import { ChemistryService } from './chemistry.service';
import { ListChemistryPairsDto } from './dto/list-chemistry-pairs.dto';
import { PlayerNetworkQueryDto } from './dto/player-network-query.dto';
import { RatePairDto } from './dto/rate-pair.dto';
import { ScoreLineupDto } from './dto/score-lineup.dto';
import { SetManualPairScoreDto } from './dto/set-manual-pair-score.dto';

@ApiTags('chemistry')
@Controller('chemistry')
export class ChemistryController {
  constructor(private readonly chemistryService: ChemistryService) {}

  @Post('rate-pair')
  @ApiOperation({ summary: 'Rate a player pair chemistry from coach observation' })
  ratePair(@Body() dto: RatePairDto) {
    return this.chemistryService.ratePair(dto);
  }

  @Post('analyze-pair-profile')
  @ApiOperation({ summary: 'Analyze pair chemistry from player style profiles (AI-first)' })
  analyzePairProfile(@Body() dto: AnalyzePairProfileDto) {
    return this.chemistryService.analyzePairProfile(dto);
  }

  @Post('analyze-squad-profile')
  @ApiOperation({ summary: 'Analyze full squad chemistry from profiles and formation simulations' })
  analyzeSquadProfile(@Body() dto: AnalyzeSquadProfileDto) {
    return this.chemistryService.analyzeSquadProfile(dto);
  }

  @Post('set-manual-score')
  @ApiOperation({ summary: 'Set manual chemistry score override (manual has priority)' })
  setManualScore(@Body() dto: SetManualPairScoreDto) {
    return this.chemistryService.setManualPairScore(dto);
  }

  @Get('matrix/:season')
  @ApiOperation({ summary: 'Get full team chemistry matrix for a season' })
  getMatrix(@Param('season') season: string) {
    return this.chemistryService.getMatrix(season);
  }

  @Get('graph/:season')
  @ApiOperation({ summary: 'Get chemistry graph (nodes and edges) for a season' })
  getGraph(@Param('season') season: string) {
    return this.chemistryService.getGraph(season);
  }

  @Get('best-pairs')
  @ApiOperation({ summary: 'Get top compatible chemistry pairs' })
  getBestPairs(@Query() query: ListChemistryPairsDto) {
    return this.chemistryService.getBestPairs(query);
  }

  @Get('conflicts')
  @ApiOperation({ summary: 'Get high-risk chemistry pairs' })
  getConflicts(@Query() query: ListChemistryPairsDto) {
    return this.chemistryService.getConflicts(query);
  }

  @Post('score-lineup')
  @ApiOperation({ summary: 'Compute chemistry impact for a proposed XI' })
  scoreLineup(@Body() dto: ScoreLineupDto) {
    return this.chemistryService.scoreLineup(dto);
  }

  @Post('generate-starting-xi')
  @ApiOperation({ summary: 'Generate a starting XI optimized for chemistry cohesion' })
  generateStartingXi(@Body() dto: GenerateStartingXiDto) {
    return this.chemistryService.generateStartingXi(dto);
  }

  @Get('player/:playerId/network')
  @ApiOperation({ summary: 'Get affinity network for one player' })
  getPlayerNetwork(@Param('playerId') playerId: string, @Query() query: PlayerNetworkQueryDto) {
    return this.chemistryService.getPlayerNetwork(playerId, query);
  }
}
