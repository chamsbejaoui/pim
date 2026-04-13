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

  @Post("end/:matchId")
  end(@Param("matchId") matchId: string) {
    return this.simulationService.endMatch(matchId);
  }
}
