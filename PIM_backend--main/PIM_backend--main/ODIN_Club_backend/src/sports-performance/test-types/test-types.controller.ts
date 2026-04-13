import { Controller, Get, Post, Body, Patch, Param, Delete, Query } from '@nestjs/common';
import { TestTypesService } from './test-types.service';
import { CreateTestTypeDto } from './dto/create-test-type.dto';
import { UpdateTestTypeDto } from './dto/update-test-type.dto';

@Controller('api/test-types')
export class TestTypesController {
    constructor(private readonly testTypesService: TestTypesService) { }

    @Post()
    create(@Body() createTestTypeDto: CreateTestTypeDto) {
        return this.testTypesService.create(createTestTypeDto);
    }

    @Get()
    findAll(@Query('activeOnly') activeOnly?: string) {
        return this.testTypesService.findAll(activeOnly === 'true');
    }

    @Get(':id')
    findOne(@Param('id') id: string) {
        return this.testTypesService.findOne(id);
    }

    @Patch(':id')
    update(@Param('id') id: string, @Body() updateTestTypeDto: UpdateTestTypeDto) {
        return this.testTypesService.update(id, updateTestTypeDto);
    }

    @Delete(':id')
    remove(@Param('id') id: string) {
        return this.testTypesService.remove(id);
    }
}
