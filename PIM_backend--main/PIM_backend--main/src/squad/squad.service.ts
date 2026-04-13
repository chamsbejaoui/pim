import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Player, PlayerDocument } from '../players/schemas/player.schema';
import { CreateSquadDto, SetSeasonSquadDto } from './dto/create-squad.dto';
import { UpdateSquadDto } from './dto/update-squad.dto';
import { Squad, SquadDocument } from './schemas/squad.schema';

const TARGET_SQUAD_SIZE = 24;
const TARGET_STARTERS = 11;
const TARGET_BENCH = 8;
const TARGET_RESERVES = 5;

@Injectable()
export class SquadService {
  constructor(
    @InjectModel(Squad.name) private readonly squadModel: Model<SquadDocument>,
    @InjectModel(Player.name) private readonly playerModel: Model<PlayerDocument>
  ) {}

  async create(createSquadDto: CreateSquadDto): Promise<Squad> {
    const normalized = await this.normalizeAndValidate(createSquadDto);
    const created = new this.squadModel({
      ...createSquadDto,
      ...normalized,
      season: createSquadDto.season.trim(),
      targetSquadSize: TARGET_SQUAD_SIZE
    });
    return created.save();
  }

  async findAll(): Promise<Squad[]> {
    return this.squadModel.find().sort({ season: -1 }).exec();
  }

  async findById(id: string): Promise<Squad> {
    const squad = await this.squadModel.findById(id).exec();
    if (!squad) {
      throw new NotFoundException(`Squad with ID "${id}" not found`);
    }
    return squad;
  }

  async findBySeason(season: string): Promise<Squad> {
    const squad = await this.squadModel.findOne({ season: season.trim() }).exec();
    if (!squad) {
      throw new NotFoundException(`Squad for season "${season}" not found`);
    }
    return squad;
  }

  async upsertBySeason(season: string, dto: SetSeasonSquadDto): Promise<Squad> {
    const payload: CreateSquadDto = {
      ...dto,
      season: season.trim()
    };

    const normalized = await this.normalizeAndValidate(payload);

    return this.squadModel
      .findOneAndUpdate(
        { season: payload.season },
        {
          ...payload,
          ...normalized,
          targetSquadSize: TARGET_SQUAD_SIZE
        },
        { new: true, upsert: true, setDefaultsOnInsert: true }
      )
      .exec();
  }

  async update(id: string, updateSquadDto: UpdateSquadDto): Promise<Squad> {
    const current = await this.findById(id);

    const merged: CreateSquadDto = {
      season: updateSquadDto.season ?? current.season,
      label: updateSquadDto.label ?? current.label,
      playerIds: updateSquadDto.playerIds ?? this.stringifyIds(current.playerIds),
      starterIds: updateSquadDto.starterIds ?? this.stringifyIds(current.starterIds),
      benchIds: updateSquadDto.benchIds ?? this.stringifyIds(current.benchIds),
      reserveIds: updateSquadDto.reserveIds ?? this.stringifyIds(current.reserveIds)
    };

    const normalized = await this.normalizeAndValidate(merged);

    const updated = await this.squadModel
      .findByIdAndUpdate(
        id,
        {
          ...merged,
          ...normalized,
          season: merged.season.trim(),
          targetSquadSize: TARGET_SQUAD_SIZE
        },
        { new: true }
      )
      .exec();

    if (!updated) {
      throw new NotFoundException(`Squad with ID "${id}" not found`);
    }
    return updated;
  }

  async remove(id: string): Promise<void> {
    const result = await this.squadModel.findByIdAndDelete(id).exec();
    if (!result) {
      throw new NotFoundException(`Squad with ID "${id}" not found`);
    }
  }

  private stringifyIds(ids: unknown[]): string[] {
    return ids.map((id) => String(id));
  }

  private async normalizeAndValidate(dto: CreateSquadDto): Promise<{
    playerIds: string[];
    starterIds: string[];
    benchIds: string[];
    reserveIds: string[];
  }> {
    const playerIds = this.normalizeIds(dto.playerIds);
    const starterIds = this.normalizeIds(dto.starterIds);
    const benchIds = this.normalizeIds(dto.benchIds);
    const explicitReserveIds = dto.reserveIds ? this.normalizeIds(dto.reserveIds) : null;

    if (playerIds.length !== TARGET_SQUAD_SIZE) {
      throw new BadRequestException(
        `A season squad must contain exactly ${TARGET_SQUAD_SIZE} players.`
      );
    }
    if (starterIds.length !== TARGET_STARTERS) {
      throw new BadRequestException(`You must provide exactly ${TARGET_STARTERS} starters.`);
    }
    if (benchIds.length !== TARGET_BENCH) {
      throw new BadRequestException(`You must provide exactly ${TARGET_BENCH} bench players.`);
    }

    this.ensureNoDuplicates(playerIds, 'playerIds');
    this.ensureNoDuplicates(starterIds, 'starterIds');
    this.ensureNoDuplicates(benchIds, 'benchIds');
    if (explicitReserveIds) {
      this.ensureNoDuplicates(explicitReserveIds, 'reserveIds');
      if (explicitReserveIds.length !== TARGET_RESERVES) {
        throw new BadRequestException(`reserveIds must contain exactly ${TARGET_RESERVES} players.`);
      }
    }

    this.ensureAllBelongToSquad(starterIds, playerIds, 'starterIds');
    this.ensureAllBelongToSquad(benchIds, playerIds, 'benchIds');

    const starterSet = new Set(starterIds);
    const benchOverlap = benchIds.find((id) => starterSet.has(id));
    if (benchOverlap) {
      throw new BadRequestException('A player cannot be both starter and bench.');
    }

    const computedReserveIds = playerIds.filter(
      (id) => !starterSet.has(id) && !benchIds.includes(id)
    );

    if (computedReserveIds.length !== TARGET_RESERVES) {
      throw new BadRequestException(
        `The remaining players must be exactly ${TARGET_RESERVES} reserves.`
      );
    }

    let reserveIds = computedReserveIds;
    if (explicitReserveIds) {
      this.ensureAllBelongToSquad(explicitReserveIds, playerIds, 'reserveIds');
      const sameReserveGroup =
        explicitReserveIds.length === computedReserveIds.length &&
        explicitReserveIds.every((id) => computedReserveIds.includes(id));
      if (!sameReserveGroup) {
        throw new BadRequestException(
          'reserveIds must match the remaining players after starters and bench are selected.'
        );
      }
      reserveIds = explicitReserveIds;
    }

    await this.ensurePlayersExistAndActive(playerIds);

    return {
      playerIds,
      starterIds,
      benchIds,
      reserveIds
    };
  }

  private normalizeIds(ids: string[]): string[] {
    return ids.map((id) => id.trim());
  }

  private ensureNoDuplicates(ids: string[], fieldName: string) {
    if (new Set(ids).size !== ids.length) {
      throw new BadRequestException(`${fieldName} contains duplicate player IDs.`);
    }
  }

  private ensureAllBelongToSquad(ids: string[], playerIds: string[], fieldName: string) {
    const allPlayerIds = new Set(playerIds);
    const outsider = ids.find((id) => !allPlayerIds.has(id));
    if (outsider) {
      throw new BadRequestException(`${fieldName} contains a player not present in playerIds.`);
    }
  }

  private async ensurePlayersExistAndActive(playerIds: string[]) {
    const players = await this.playerModel
      .find({ _id: { $in: playerIds } })
      .select('_id status')
      .lean()
      .exec();

    if (players.length !== playerIds.length) {
      const existingIds = new Set(players.map((player) => String(player._id)));
      const missing = playerIds.filter((id) => !existingIds.has(id));
      throw new BadRequestException(`Unknown player IDs: ${missing.join(', ')}`);
    }

    const archived = players
      .filter((player) => player.status === 'archived')
      .map((player) => String(player._id));

    if (archived.length > 0) {
      throw new BadRequestException(
        `Archived players cannot be selected in season squad: ${archived.join(', ')}`
      );
    }
  }
}
