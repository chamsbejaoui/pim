import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import { MedicalController } from "./medical.controller";
import { MedicalService } from "./medical.service";
import { PlayersModule } from "../players/players.module";
import { MedicalRecord, MedicalRecordSchema } from "./schemas/medical-record.schema";

@Module({
  imports: [
    PlayersModule,
    MongooseModule.forFeature([
      { name: MedicalRecord.name, schema: MedicalRecordSchema },
    ]),
  ],
  controllers: [MedicalController],
  providers: [MedicalService],
  exports: [MedicalService],
})
export class MedicalModule {}