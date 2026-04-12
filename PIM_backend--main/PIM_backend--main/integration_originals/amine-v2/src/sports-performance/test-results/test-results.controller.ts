import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { TestResultsService } from './test-results.service';
import { CreateTestResultDto } from './dto/create-test-result.dto';
import { UpdateTestResultDto } from './dto/update-test-result.dto';

@Controller('event-players/:eventPlayerId/test-results')
export class TestResultsController {
    constructor(private readonly testResultsService: TestResultsService) { }

    @Post()
    create(
        @Param('eventPlayerId') eventPlayerId: string,
        @Body() dto: CreateTestResultDto,
    ) {
        return this.testResultsService.create(eventPlayerId, dto);
    }

    @Get()
    findByEventPlayer(@Param('eventPlayerId') eventPlayerId: string) {
        return this.testResultsService.findByEventPlayer(eventPlayerId);
    }
}

@Controller('test-results')
export class TestResultsManagementController {
    constructor(private readonly testResultsService: TestResultsService) { }

    @Get(':id')
    findOne(@Param('id') id: string) {
        return this.testResultsService.findOne(id);
    }

    @Patch(':id')
    update(@Param('id') id: string, @Body() dto: UpdateTestResultDto) {
        return this.testResultsService.update(id, dto);
    }

    @Delete(':id')
    remove(@Param('id') id: string) {
        return this.testResultsService.remove(id);
    }
}
