import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TestTypesService } from './test-types.service';
import { TestTypesController } from './test-types.controller';
import { TestType, TestTypeSchema } from './entities/test-type.entity';

@Module({
    imports: [
        MongooseModule.forFeature([{ name: TestType.name, schema: TestTypeSchema }]),
    ],
    controllers: [TestTypesController],
    providers: [TestTypesService],
    exports: [TestTypesService],
})
export class TestTypesModule { }
