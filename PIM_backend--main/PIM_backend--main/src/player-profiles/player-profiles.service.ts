import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Player, PlayerDocument } from '../players/schemas/player.schema';
import { ListPlayerStyleProfilesDto } from './dto/list-player-style-profiles.dto';
import { UpsertPlayerStyleProfileDto } from './dto/upsert-player-style-profile.dto';
import {
  PlayerStyleProfile,
  PlayerStyleProfileDocument
} from './schemas/player-style-profile.schema';

@Injectable()
export class PlayerProfilesService {
  constructor(
    @InjectModel(PlayerStyleProfile.name)
    private readonly profileModel: Model<PlayerStyleProfileDocument>,
    @InjectModel(Player.name)
    private readonly playerModel: Model<PlayerDocument>
  ) {}

  async upsertProfile(playerId: string, dto: UpsertPlayerStyleProfileDto) {
    const validPlayerId = this.assertObjectId(playerId, 'Invalid player ID');
    await this.assertPlayerExists(validPlayerId);

    const season = dto.season ?? this.defaultSeason();
    const existing = await this.profileModel.findOne({ season, playerId: validPlayerId }).lean().exec();

    const nextPayload = {
      season,
      playerId: validPlayerId,
      possessionPlay: dto.possessionPlay ?? existing?.possessionPlay ?? 5,
      selfishness: dto.selfishness ?? existing?.selfishness ?? 5,
      oneTouchPreference: dto.oneTouchPreference ?? existing?.oneTouchPreference ?? 5,
      directPlay: dto.directPlay ?? existing?.directPlay ?? 5,
      riskTaking: dto.riskTaking ?? existing?.riskTaking ?? 5,
      pressingIntensity: dto.pressingIntensity ?? existing?.pressingIntensity ?? 5,
      offBallMovement: dto.offBallMovement ?? existing?.offBallMovement ?? 5,
      communication: dto.communication ?? existing?.communication ?? 5,
      defensiveDiscipline: dto.defensiveDiscipline ?? existing?.defensiveDiscipline ?? 5,
      creativity: dto.creativity ?? existing?.creativity ?? 5,
      preferredStyles: dto.preferredStyles ?? existing?.preferredStyles ?? [],
      notes: dto.notes ?? existing?.notes,
      updatedBy: dto.updatedBy ?? existing?.updatedBy
    };

    const profile = await this.profileModel
      .findOneAndUpdate(
        { season, playerId: validPlayerId },
        { $set: nextPayload },
        { new: true, upsert: true, setDefaultsOnInsert: true }
      )
      .lean()
      .exec();

    return this.toProfileView(profile as PlayerStyleProfileDocument);
  }

  async getProfile(playerId: string, season?: string) {
    const validPlayerId = this.assertObjectId(playerId, 'Invalid player ID');
    await this.assertPlayerExists(validPlayerId);

    const profile = season
      ? await this.profileModel.findOne({ season, playerId: validPlayerId }).lean().exec()
      : await this.profileModel.findOne({ playerId: validPlayerId }).sort({ season: -1, updatedAt: -1 }).lean().exec();

    if (!profile) {
      throw new NotFoundException('Player style profile not found');
    }

    return this.toProfileView(profile as PlayerStyleProfileDocument);
  }

  async listProfiles(query: ListPlayerStyleProfilesDto) {
    const season = query.season ?? (await this.resolveLatestSeason());
    const limit = query.limit ?? 120;

    const profiles = await this.profileModel.find({ season }).limit(limit).sort({ updatedAt: -1 }).lean().exec();

    const playerIds = profiles.map((profile) => String(profile.playerId));
    const players = await this.playerModel
      .find({ _id: { $in: playerIds } })
      .select('_id name firstName lastName position')
      .lean()
      .exec();

    const playerMap = new Map<string, any>();
    for (const player of players) {
      playerMap.set(String(player._id), player);
    }

    const items = profiles.map((profile) => {
      const linkedPlayer = playerMap.get(String(profile.playerId));
      return this.toProfileView(profile as PlayerStyleProfileDocument, linkedPlayer);
    });

    return {
      season,
      total: items.length,
      items
    };
  }

  private toProfileView(profile: PlayerStyleProfileDocument, linkedPlayer?: any) {
    const playerId = String(profile.playerId);
    const playerName = linkedPlayer ? this.playerName(linkedPlayer) : playerId;

    return {
      id: String(profile._id),
      season: profile.season,
      playerId,
      playerName,
      position: linkedPlayer?.position,
      style: {
        possessionPlay: profile.possessionPlay,
        selfishness: profile.selfishness,
        oneTouchPreference: profile.oneTouchPreference,
        directPlay: profile.directPlay,
        riskTaking: profile.riskTaking,
        pressingIntensity: profile.pressingIntensity,
        offBallMovement: profile.offBallMovement,
        communication: profile.communication,
        defensiveDiscipline: profile.defensiveDiscipline,
        creativity: profile.creativity
      },
      preferredStyles: profile.preferredStyles,
      notes: profile.notes,
      updatedBy: profile.updatedBy,
      updatedAt: (profile as any).updatedAt
    };
  }

  private playerName(player: any): string {
    if (player?.name && String(player.name).trim().length > 0) {
      return String(player.name).trim();
    }

    const firstName = String(player?.firstName ?? '').trim();
    const lastName = String(player?.lastName ?? '').trim();
    const fullName = `${firstName} ${lastName}`.trim();
    if (fullName.length > 0) {
      return fullName;
    }

    return String(player?._id ?? 'Unknown');
  }

  private assertObjectId(value: string, message: string): Types.ObjectId {
    if (!Types.ObjectId.isValid(value)) {
      throw new BadRequestException(message);
    }
    return new Types.ObjectId(value);
  }

  private async assertPlayerExists(playerId: Types.ObjectId) {
    const exists = await this.playerModel.exists({ _id: playerId });
    if (!exists) {
      throw new NotFoundException('Player not found');
    }
  }

  private defaultSeason(): string {
    const now = new Date();
    const year = now.getMonth() >= 6 ? now.getFullYear() : now.getFullYear() - 1;
    return `${year}-${year + 1}`;
  }

  private async resolveLatestSeason(): Promise<string> {
    const latest = await this.profileModel.findOne().sort({ season: -1, updatedAt: -1 }).lean().exec();
    if (!latest?.season) {
      throw new BadRequestException('No player style profiles found yet. Provide a season first.');
    }
    return latest.season;
  }
}
