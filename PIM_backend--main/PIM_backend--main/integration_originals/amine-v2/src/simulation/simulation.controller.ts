import { Body, Controller, Get, Param, Post } from "@nestjs/common";
import { SimulationService } from "./simulation.service";

@Controller("simulation")
export class SimulationController {
  constructor(private readonly simulationService: SimulationService) {}

  @Post("start")
  start(@Body() body: { playerIds?: string[] }) {
    return this.simulationService.startMatch(body?.playerIds);
  }

  @Get("available-players")
  availablePlayers() {
    return this.simulationService.getAvailablePlayers();
  }

  @Get("history")
  history() {
    return this.simulationService.getMatchHistory();
  }

  @Post("end/:matchId")
  end(
    @Param("matchId") matchId: string,
    @Body()
    body?: {
      stats?: {
        homeScore: number;
        awayScore: number;
        possessionHome: number;
        shotsHome: number;
        shotsAway: number;
        shotsOnTargetHome: number;
        shotsOnTargetAway: number;
      };
    },
  ) {
    return this.simulationService.endMatch(matchId, body?.stats);
  }
}
