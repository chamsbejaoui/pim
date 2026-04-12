import { Controller, Get, Post, Body, Param, Put, Delete } from '@nestjs/common';
import { SeasonPlansService } from './season-plans.service';
import {
  CreateCollectivePreparationDto,
  CreateSeasonPlanDto,
  CreateWeeklyCollectiveCheckinDto,
} from './dto/create-season-plan.dto';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('season-plans')
@Controller('season-plans')
export class SeasonPlansController {
  constructor(private readonly seasonPlansService: SeasonPlansService) {}

  @Post()
  @ApiOperation({ summary: 'Créer un nouveau plan de saison' })
  create(@Body() createDto: CreateSeasonPlanDto) {
    return this.seasonPlansService.create(createDto);
  }

  @Get()
  @ApiOperation({ summary: 'Lister tous les plans de saison' })
  findAll() {
    return this.seasonPlansService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obtenir un plan de saison par son ID' })
  findOne(@Param('id') id: string) {
    return this.seasonPlansService.findOne(id);
  }

  @Get(':id/dashboard')
  @ApiOperation({ summary: 'Obtenir le dashboard professionnel de preparation collective' })
  getDashboard(@Param('id') id: string) {
    return this.seasonPlansService.getDashboard(id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Mettre à jour un plan de saison' })
  update(@Param('id') id: string, @Body() updateDto: any) {
    return this.seasonPlansService.update(id, updateDto);
  }

  @Put(':id/collective-preparation')
  @ApiOperation({ summary: 'Mettre a jour la strategie de preparation collective' })
  updateCollectivePreparation(
    @Param('id') id: string,
    @Body() dto: CreateCollectivePreparationDto,
  ) {
    return this.seasonPlansService.updateCollectivePreparation(id, dto);
  }

  @Post(':id/weekly-checkins')
  @ApiOperation({ summary: 'Ajouter ou mettre a jour un bilan hebdomadaire collectif' })
  addWeeklyCheckin(
    @Param('id') id: string,
    @Body() dto: CreateWeeklyCollectiveCheckinDto,
  ) {
    return this.seasonPlansService.addWeeklyCheckin(id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Supprimer un plan de saison' })
  remove(@Param('id') id: string) {
    return this.seasonPlansService.remove(id);
  }

  @Post(':id/macro/:macroId/generate')
  @ApiOperation({ summary: 'Générer des micro-cycles par IA pour un macro-cycle donné' })
  generateMicroCycles(
    @Param('id') id: string,
    @Param('macroId') macroId: string,
    @Body('weeksCount') weeksCount: number = 4,
  ) {
    return this.seasonPlansService.generateMicroCycles(id, macroId, weeksCount);
  }
}
