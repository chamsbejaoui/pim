import { Module } from "@nestjs/common";
import { ProviderRegistryService } from "./provider-registry.service";
import { ApiFootballAdapter } from "./adapters/api-football.adapter";

@Module({
  providers: [ProviderRegistryService, ApiFootballAdapter],
  exports: [ProviderRegistryService],
})
export class ProvidersModule {}
