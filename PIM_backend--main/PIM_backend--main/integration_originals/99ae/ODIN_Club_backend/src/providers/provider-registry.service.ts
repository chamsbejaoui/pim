import { Injectable } from '@nestjs/common';
import { ApiFootballAdapter } from './adapters/api-football.adapter';

@Injectable()
export class ProviderRegistryService {

  constructor(
    private readonly apiFootball: ApiFootballAdapter,
  ) {}

  getProvider(provider: string) {

    if (provider === 'api-football') {
      return this.apiFootball;
    }

    throw new Error(`Unknown provider: ${provider}`);
  }
}