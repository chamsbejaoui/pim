import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PlayersModule } from '../../players/players.module';
import { CognitiveLabController } from './cognitive-lab.controller';
import { CognitiveLabService } from './services/cognitive-lab.service';
import { CognitiveAiService } from './services/cognitive-ai.service';
import { CognitiveSession, CognitiveSessionSchema } from './entities/cognitive-session.entity';

@Module({
    imports: [
        MongooseModule.forFeature([
            { name: CognitiveSession.name, schema: CognitiveSessionSchema }
        ]),
        PlayersModule
    ],
    controllers: [CognitiveLabController],
    providers: [CognitiveLabService, CognitiveAiService],
    exports: [CognitiveLabService]
})
export class CognitiveLabModule { }
