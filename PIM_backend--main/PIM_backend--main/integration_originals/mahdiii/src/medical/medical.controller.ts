import { Body, Controller, Get, Param, Post } from "@nestjs/common";
import { MedicalService } from "./medical.service";

@Controller("medical")
export class MedicalController {
  constructor(private readonly medicalService: MedicalService) {}

  @Post("analyze/:playerId")
  async analyze(
    @Param("playerId") playerId: string,
    @Body() sessionData: { fatigue: number; minutes: number; load: number }
  ) {
    try {
      return await this.medicalService.analyzePlayer(playerId, sessionData);
    } catch (error) {
      console.error("Medical analysis failed:", error);
      throw error;
    }
  }

  @Get("history/:playerId")
  getHistory(@Param("playerId") playerId: string) {
    return this.medicalService.getHistory(playerId);
  }
}