import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import { Match, MatchSchema } from "./schemas/match.schema";
import { MatchPlayer, MatchPlayerSchema } from "./schemas/match-player.schema";

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Match.name, schema: MatchSchema },
      { name: MatchPlayer.name, schema: MatchPlayerSchema },
    ]),
  ],
  exports: [MongooseModule],
})
export class MatchesModule {}
