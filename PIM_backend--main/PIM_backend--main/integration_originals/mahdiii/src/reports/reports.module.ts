import { Module } from "@nestjs/common";
import { ReportsService } from "./reports.service";
import { ReportsController } from "./reports.controller";
import { MatchesModule } from "../matches/matches.module";
import { PlayersModule } from "../players/players.module";
import { MedicalModule } from "../medical/medical.module";
import { AiModule } from "../ai/ai.module";

@Module({
  imports: [MatchesModule, PlayersModule, MedicalModule, AiModule],
  providers: [ReportsService],
  controllers: [ReportsController],
})
export class ReportsModule {}
