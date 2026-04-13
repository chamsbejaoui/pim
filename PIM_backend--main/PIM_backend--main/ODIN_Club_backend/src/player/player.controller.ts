import {
    Controller,
    Get,
    Post,
    Body,
    Param,
    Put,
    Delete,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { PlayerService } from './player.service';
import { CreatePlayerDto } from './dto/create-player.dto';
import { UpdatePlayerDto } from './dto/update-player.dto';

@ApiTags('players')
@Controller('players')
export class PlayerController {
    constructor(private readonly playerService: PlayerService) { }

    @Post()
    @ApiOperation({ summary: 'Create a new player' })
    @ApiResponse({ status: 201, description: 'Player created successfully' })
    create(@Body() createPlayerDto: CreatePlayerDto) {
        return this.playerService.create(createPlayerDto);
    }

    @Post('bulk')
    @ApiOperation({ summary: 'Create multiple players at once' })
    @ApiResponse({ status: 201, description: 'Players created successfully' })
    createMany(@Body() players: CreatePlayerDto[]) {
        return this.playerService.createMany(players);
    }

    @Post('archive')
    @ApiOperation({ summary: 'Archive multiple players by IDs' })
    @ApiResponse({ status: 200, description: 'Players archived successfully' })
    archiveMany(@Body() body: { ids: string[] }) {
        return this.playerService.archiveMany(body.ids);
    }

    @Get()
    @ApiOperation({ summary: 'Get all active players' })
    @ApiResponse({ status: 200, description: 'List of all active players' })
    findAll() {
        return this.playerService.findAll();
    }

    @Get('archived')
    @ApiOperation({ summary: 'Get all archived players' })
    @ApiResponse({ status: 200, description: 'List of archived players' })
    findArchived() {
        return this.playerService.findArchived();
    }

    @Get('labeled')
    @ApiOperation({ summary: 'Get all labeled players (with label != null)' })
    @ApiResponse({ status: 200, description: 'List of labeled players' })
    findLabeled() {
        return this.playerService.findLabeled();
    }

    @Get('count')
    @ApiOperation({ summary: 'Get total number of active players' })
    @ApiResponse({ status: 200, description: 'Player count' })
    async count() {
        const total = await this.playerService.count();
        return { total };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get a player by ID' })
    @ApiResponse({ status: 200, description: 'Player details' })
    @ApiResponse({ status: 404, description: 'Player not found' })
    findOne(@Param('id') id: string) {
        return this.playerService.findById(id);
    }

    @Put(':id')
    @ApiOperation({ summary: 'Update a player' })
    @ApiResponse({ status: 200, description: 'Player updated successfully' })
    @ApiResponse({ status: 404, description: 'Player not found' })
    update(@Param('id') id: string, @Body() updatePlayerDto: UpdatePlayerDto) {
        return this.playerService.update(id, updatePlayerDto);
    }

    @Delete(':id')
    @ApiOperation({ summary: 'Delete a player' })
    @ApiResponse({ status: 200, description: 'Player deleted successfully' })
    @ApiResponse({ status: 404, description: 'Player not found' })
    remove(@Param('id') id: string) {
        return this.playerService.remove(id);
    }
}
