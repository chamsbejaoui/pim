import { Controller, Get, Post, Body, Patch, Param, Delete, Query } from '@nestjs/common';
import { ExercisesService } from './exercises.service';
import { CreateExerciseDto } from './dto/create-exercise.dto';
import { UpdateExerciseDto } from './dto/update-exercise.dto';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('exercises')
@Controller('exercises')
export class ExercisesController {
    constructor(private readonly exercisesService: ExercisesService) { }

    @Post()
    @ApiOperation({ summary: 'Create a new exercise' })
    create(@Body() createExerciseDto: CreateExerciseDto) {
        return this.exercisesService.create(createExerciseDto);
    }

    @Get()
    @ApiOperation({ summary: 'Get all exercises' })
    findAll(@Query() query: any) {
        return this.exercisesService.findAll(query);
    }

    // ⚠️ Routes spécifiques AVANT la route générique :id
    @Get('insights/:playerId')
    @ApiOperation({ summary: 'Get AI insights for a player (weaknesses and match load)' })
    getPlayerInsights(@Param('playerId') playerId: string) {
        return this.exercisesService.getPlayerInsights(playerId);
    }

    @Post('ai-generate')
    @ApiOperation({ summary: 'Generate a smart drill using AI' })
    generateAiDrill(@Body() context: any) {
        return this.exercisesService.generateAndSaveAiDrill(context);
    }

    @Post(':id/complete')
    @ApiOperation({ summary: 'Record exercise session completion for a player' })
    completeSession(
        @Param('id') id: string,
        @Body() body: { playerId: string; durationSeconds: number; lapsCount: number }
    ) {
        return this.exercisesService.recordCompletion(id, body);
    }

    @Patch(':id/adapt')
    @ApiOperation({ summary: 'Adapt difficulty based on performance ratio' })
    adaptDifficulty(
        @Param('id') id: string,
        @Body() body: { performanceRatio: number },
    ) {
        return this.exercisesService.adaptDifficulty(id, body.performanceRatio);
    }

    // Routes génériques :id en dernier
    @Get(':id')
    @ApiOperation({ summary: 'Get a single exercise' })
    findOne(@Param('id') id: string) {
        return this.exercisesService.findOne(id);
    }

    @Patch(':id')
    @ApiOperation({ summary: 'Update an exercise' })
    update(@Param('id') id: string, @Body() updateExerciseDto: UpdateExerciseDto) {
        return this.exercisesService.update(id, updateExerciseDto);
    }

    @Delete(':id')
    @ApiOperation({ summary: 'Delete an exercise' })
    remove(@Param('id') id: string) {
        return this.exercisesService.remove(id);
    }
}
