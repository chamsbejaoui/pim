import { Body, Controller, Get, Param, Put, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { ListPlayerStyleProfilesDto } from './dto/list-player-style-profiles.dto';
import { UpsertPlayerStyleProfileDto } from './dto/upsert-player-style-profile.dto';
import { PlayerProfilesService } from './player-profiles.service';

@ApiTags('player-profiles')
@Controller('player-profiles')
export class PlayerProfilesController {
  constructor(private readonly playerProfilesService: PlayerProfilesService) {}

  @Get()
  @ApiOperation({ summary: 'List player style profiles for a season' })
  listProfiles(@Query() query: ListPlayerStyleProfilesDto) {
    return this.playerProfilesService.listProfiles(query);
  }

  @Get(':playerId')
  @ApiOperation({ summary: 'Get a player style profile by player ID' })
  getProfile(@Param('playerId') playerId: string, @Query('season') season?: string) {
    return this.playerProfilesService.getProfile(playerId, season);
  }

  @Put(':playerId')
  @ApiOperation({ summary: 'Create or update a player style profile' })
  upsertProfile(@Param('playerId') playerId: string, @Body() dto: UpsertPlayerStyleProfileDto) {
    return this.playerProfilesService.upsertProfile(playerId, dto);
  }
}
