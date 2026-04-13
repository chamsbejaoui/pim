import { Module } from "@nestjs/common";
import { IngestionService } from "./ingestion.service";
import { IngestionController } from "./ingestion.controller";
import { ProvidersModule } from "../providers/providers.module";
import { PlayersModule } from "../players/players.module";
import { MatchesModule } from "../matches/matches.module";
import { MedicalModule } from "../medical/medical.module";

@Module({
  imports: [ProvidersModule, PlayersModule, MatchesModule, MedicalModule],
  providers: [IngestionService],
  controllers: [IngestionController],
})
export class IngestionModule {}
