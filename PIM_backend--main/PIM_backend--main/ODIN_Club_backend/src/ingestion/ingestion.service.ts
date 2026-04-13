import { Injectable, Logger } from "@nestjs/common";
import { ProviderRegistryService } from "../providers/provider-registry.service";

@Injectable()
export class IngestionService {

  private readonly logger = new Logger(IngestionService.name);

  constructor(
    private readonly registry: ProviderRegistryService,
  ) {}

  /**
   * Temporary ingestion step:
   * fetch raw data from provider and return it.
   * (no Mongo write yet – we validate the provider first)
   */
  async ingestMatch(providerMatchId: string, provider = "api-football") {

    const adapter = this.registry.getProvider(provider);

    const bundle = await adapter.getMatchBundle(providerMatchId);

    // Only log size, not full object
    this.logger.log(
      `Fetched bundle from ${provider} for match ${providerMatchId}`,
    );

    return {
      status: "ok",
      provider,
      received: {
        fixture: !!bundle.fixture,
        lineups: Array.isArray(bundle.lineups)
          ? bundle.lineups.length
          : 0,
        players: Array.isArray(bundle.players)
          ? bundle.players.length
          : 0,
      },
    };
  }
}