import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { ConfigModule } from '@nestjs/config';
import { AiService } from './ai.service';
import { AiController } from './ai.controller';
import { PythonProcessService } from './python-process.service';

@Module({
    imports: [
        ConfigModule,
        HttpModule.register({
            timeout: 60000,
            maxRedirects: 5,
        }),
    ],
    controllers: [AiController],
    providers: [AiService, PythonProcessService],
    exports: [AiService, PythonProcessService],
})
export class AiModule { }
