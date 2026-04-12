import { Injectable } from "@nestjs/common";
import axios from "axios";

@Injectable()
export class ApiFootballAdapter {

  async getMatchBundle(fixtureId: string) {

const apiKey = process.env.API_FOOTBALL_KEY;
    console.log("API KEY LOADED =", apiKey);

    const res = await axios.get(
      "https://v3.football.api-sports.io/fixtures",
      {
        params: { date: "2026-02-13" },
        headers: {
          "x-apisports-key": apiKey as string,
        },
      }
    );

    const fixtures = res.data?.response ?? [];

    const fixture = fixtures.find(
      (f: any) => String(f.fixture.id) === String(fixtureId)
    );

    if (!fixture) {
      throw new Error("Fixture not found in free plan window");
    }

    return {
      fixture,
      lineups: [],
      players: [],
    };
  }
}