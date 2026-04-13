import { Module } from "@nestjs/common";
import { SimulationController } from "./simulation.controller";
import { SimulationService } from "./simulation.service";
import { PlayersModule } from "../players/players.module";
import { MedicalModule } from "../medical/medical.module";
import { MongooseModule } from "@nestjs/mongoose";
import { MedicalRecord, MedicalRecordSchema } from "../medical/schemas/medical-record.schema";
import { SimulationMatch, SimulationMatchSchema } from "./schemas/simulation-match.schema";

@Module({
  imports: [
    PlayersModule,
    MedicalModule,
    MongooseModule.forFeature([
      { name: MedicalRecord.name, schema: MedicalRecordSchema },
      { name: SimulationMatch.name, schema: SimulationMatchSchema },
    ]),
  ],
  controllers: [SimulationController],
  providers: [SimulationService],
})
export class SimulationModule {}
