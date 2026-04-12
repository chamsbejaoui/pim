export interface NormalizedMatch {
  provider: { name: string; matchId: string };
  date: string;
  competition: { name: string; season: string };
  teams: { home: string; away: string };
  score: { home: number; away: number };
}

export interface NormalizedPlayer {
  provider: { name: string; playerId: string };
  name: string;
  age: number;
  position: string;
  dateOfBirth?: string;
}

export interface NormalizedMatchPlayer {
  provider: { name: string; matchId: string; playerId: string };
  team: { name: string };
  lineup: { status: "starter" | "sub"; minutes: number; position: string };
  stats: {
    rating: number;
    goals: number;
    assists: number;
    shots: number;
    passes: number;
    tackles: number;
    yellowCards: number;
    redCards: number;
  };
}

export interface NormalizedMedical {
  provider: { name: string; playerId: string };
  injuries: Array<{
    type: string;
    startDate: string;
    endDate?: string;
    status: "active" | "recovered";
    severity: "low" | "medium" | "high";
    notes?: string;
  }>;
  recoveryEstimateDays?: number;
  lastUpdated: string;
}

export interface NormalizedFitness {
  provider: { name: string; playerId: string };
  workload: { acute: number; chronic: number; ratio: number };
  fitnessScore: number;
  fatigueScore: number;
  lastUpdated: string;
}

export interface ProviderAdapter {
  name: string;
  fetchMatchBundle(
    providerMatchId: string,
  ): Promise<{
    match: NormalizedMatch;
    players: NormalizedPlayer[];
    matchPlayers: NormalizedMatchPlayer[];
    medical: NormalizedMedical[];
    fitness: NormalizedFitness[];
  }>;
}
