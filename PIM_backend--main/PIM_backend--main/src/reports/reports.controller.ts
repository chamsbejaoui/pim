import { Controller, Get, Param, Query } from "@nestjs/common";
import { ReportsService } from "./reports.service";

@Controller("reports")
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get("matches/:providerMatchId/players/:providerPlayerId")
  async getMatchPlayerReport(
    @Param("providerMatchId") providerMatchId: string,
    @Param("providerPlayerId") providerPlayerId: string,
    @Query("provider") provider?: string,
  ) {
    return this.reportsService.getMatchPlayerReport(
      providerMatchId,
      providerPlayerId,
      provider,
    );
  }
}
