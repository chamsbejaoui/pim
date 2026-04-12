import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Player, PlayerDocument } from './schemas/player.schema';
import { CreatePlayerDto } from './dto/create-player.dto';
import { UpdatePlayerDto } from './dto/update-player.dto';

@Injectable()
export class PlayersService {
  constructor(@InjectModel(Player.name) private playerModel: Model<PlayerDocument>) {}

  async create(createPlayerDto: CreatePlayerDto): Promise<Player> {
    const player = new this.playerModel(createPlayerDto);
    return player.save();
  }

  async createMany(players: CreatePlayerDto[]): Promise<Player[]> {
    const created: Player[] = [];
    for (const dto of players) {
      const player = new this.playerModel(dto);
      created.push(await player.save());
    }
    return created;
  }

  async findAll(includeArchived = false): Promise<Player[]> {
    if (includeArchived) {
      return this.playerModel.find().exec();
    }
    return this.playerModel
      .find({ $or: [{ status: 'active' }, { status: { $exists: false } }] })
      .exec();
  }

  async findArchived(): Promise<Player[]> {
    return this.playerModel.find({ status: 'archived' }).exec();
  }

  async findById(id: string): Promise<Player> {
    const player = await this.playerModel.findById(id).exec();
    if (!player) {
      throw new NotFoundException(`Player with ID "${id}" not found`);
    }
    return player;
  }

  async update(id: string, updatePlayerDto: UpdatePlayerDto): Promise<Player> {
    const player = await this.playerModel
      .findByIdAndUpdate(id, updatePlayerDto, { new: true })
      .exec();
    if (!player) {
      throw new NotFoundException(`Player with ID "${id}" not found`);
    }
    return player;
  }

  async remove(id: string): Promise<void> {
    const result = await this.playerModel.findByIdAndDelete(id).exec();
    if (!result) {
      throw new NotFoundException(`Player with ID "${id}" not found`);
    }
  }

  async count(): Promise<number> {
    return this.playerModel
      .countDocuments({ $or: [{ status: 'active' }, { status: { $exists: false } }] })
      .exec();
  }

  async findLabeled(): Promise<Player[]> {
    return this.playerModel.find({ label: { $ne: null } }).exec();
  }

  async archiveMany(ids: string[]): Promise<{ archivedCount: number }> {
    const result = await this.playerModel
      .updateMany({ _id: { $in: ids } }, { $set: { status: 'archived' } })
      .exec();
    return { archivedCount: result.modifiedCount };
  }
}
