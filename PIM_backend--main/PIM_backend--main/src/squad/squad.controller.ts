import { Body, Controller, Delete, Get, Param, Post, Put } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { CreateSquadDto, SetSeasonSquadDto } from './dto/create-squad.dto';
import { UpdateSquadDto } from './dto/update-squad.dto';
import { SquadService } from './squad.service';

@ApiTags('squad')
@Controller('squad')
export class SquadController {
  constructor(private readonly squadService: SquadService) {}

  @Post()
  @ApiOperation({ summary: 'Creer le squad de saison (24 = 11 titulaires + 8 banc + 5 reserves)' })
  create(@Body() createSquadDto: CreateSquadDto) {
    return this.squadService.create(createSquadDto);
  }

  @Get()
  @ApiOperation({ summary: 'Lister tous les squads de saison' })
  findAll() {
    return this.squadService.findAll();
  }

  @Get('season/:season')
  @ApiOperation({ summary: 'Recuperer le squad d une saison' })
  findBySeason(@Param('season') season: string) {
    return this.squadService.findBySeason(season);
  }

  @Put('season/:season')
  @ApiOperation({ summary: 'Creer ou remplacer le squad d une saison' })
  setForSeason(@Param('season') season: string, @Body() dto: SetSeasonSquadDto) {
    return this.squadService.upsertBySeason(season, dto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Recuperer un squad par ID' })
  findOne(@Param('id') id: string) {
    return this.squadService.findById(id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Mettre a jour un squad' })
  update(@Param('id') id: string, @Body() updateSquadDto: UpdateSquadDto) {
    return this.squadService.update(id, updateSquadDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Supprimer un squad' })
  remove(@Param('id') id: string) {
    return this.squadService.remove(id);
  }
}
