import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Player, PlayerDocument } from './entities/player.entity';
import { CreatePlayerDto } from './dto/create-player.dto';
import { UpdatePlayerDto } from './dto/update-player.dto';

@Injectable()
export class PlayersService {
    constructor(
        @InjectModel(Player.name) private playerModel: Model<PlayerDocument>,
    ) { }

    async create(createPlayerDto: CreatePlayerDto): Promise<Player> {
        const player = new this.playerModel(createPlayerDto);
        return player.save();
    }

    async findAll(): Promise<Player[]> {
        return this.playerModel.find({ status: { $ne: 'archived' } }).exec();
    }

    async getArchived(): Promise<Player[]> {
        return this.playerModel.find({ status: 'archived' }).exec();
    }

    async getCount(): Promise<{ total: number }> {
        const total = await this.playerModel.countDocuments().exec();
        return { total };
    }

    async archiveMany(ids: string[]): Promise<any> {
        // Filter out invalid MongoDB ObjectIds to prevent CastError 500
        const validIds = ids.filter(id => Types.ObjectId.isValid(id));

        if (validIds.length === 0) {
            return { archivedCount: 0, players: [] };
        }

        // Find players to archive
        const playersToArchive = await this.playerModel.find({ _id: { $in: validIds } }).exec();

        // Update their status to 'archived'
        const result = await this.playerModel.updateMany(
            { _id: { $in: validIds } },
            { $set: { status: 'archived' } }
        ).exec();

        return {
            archivedCount: result.modifiedCount,
            players: playersToArchive,
        };
    }

    async findOne(id: string): Promise<Player> {
        if (!id || !Types.ObjectId.isValid(id)) {
            throw new NotFoundException(`Player with ID ${id} not found`);
        }
        const player = await this.playerModel.findById(id).exec();
        if (!player) {
            throw new NotFoundException(`Player with ID ${id} not found`);
        }
        return player;
    }

    async update(id: string, updatePlayerDto: UpdatePlayerDto): Promise<Player> {
        if (!id || !Types.ObjectId.isValid(id)) {
            throw new NotFoundException(`Player with ID ${id} not found`);
        }
        const player = await this.playerModel
            .findByIdAndUpdate(id, updatePlayerDto, { new: true })
            .exec();
        if (!player) {
            throw new NotFoundException(`Player with ID ${id} not found`);
        }
        return player;
    }

    async remove(id: string): Promise<void> {
        if (!id || !Types.ObjectId.isValid(id)) {
            throw new NotFoundException(`Player with ID ${id} not found`);
        }
        const result = await this.playerModel.findByIdAndDelete(id).exec();
        if (!result) {
            throw new NotFoundException(`Player with ID ${id} not found`);
        }
    }
}
