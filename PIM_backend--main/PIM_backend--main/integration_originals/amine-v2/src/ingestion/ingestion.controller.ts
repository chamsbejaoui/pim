import { Controller, Param, Post, Query } from "@nestjs/common";
import { IngestionService } from "./ingestion.service";

@Controller("ingestion")
export class IngestionController {
  constructor(private readonly ingestionService: IngestionService) {}

  @Post("matches/:providerMatchId")
  async ingestMatch(
    @Param("providerMatchId") providerMatchId: string,
    @Query("provider") provider?: string,
  ) {
    return this.ingestionService.ingestMatch(providerMatchId, provider);
  }
}
