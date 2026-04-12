import { Injectable, NotFoundException, ConflictException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { EventPlayer, EventPlayerDocument } from './entities/event-player.entity';
import { AddPlayerToEventDto } from './dto/add-player-to-event.dto';
import { UpdateEventPlayerDto } from './dto/update-event-player.dto';

@Injectable()
export class EventPlayersService {
    constructor(
        @InjectModel(EventPlayer.name) private eventPlayerModel: Model<EventPlayerDocument>,
    ) { }

    async addPlayerToEvent(eventId: string, dto: AddPlayerToEventDto): Promise<EventPlayer> {
        if (!Types.ObjectId.isValid(eventId)) throw new BadRequestException(`Invalid Event ID: ${eventId}`);
        if (!Types.ObjectId.isValid(dto.playerId)) throw new BadRequestException(`Invalid Player ID: ${dto.playerId}`);

        // Vérifier si le joueur est déjà dans l'événement
        const existing = await this.eventPlayerModel
            .findOne({
                eventId: new Types.ObjectId(eventId),
                playerId: new Types.ObjectId(dto.playerId),
            })
            .exec();

        if (existing) {
            throw new ConflictException('Player is already added to this event');
        }

        const eventPlayer = new this.eventPlayerModel({
            eventId: new Types.ObjectId(eventId),
            playerId: new Types.ObjectId(dto.playerId),
            status: dto.status,
            coachNotes: dto.coachNotes,
        });

        return eventPlayer.save();
    }

    async findByEvent(eventId: string): Promise<EventPlayer[]> {
        if (!Types.ObjectId.isValid(eventId)) return [];

        return this.eventPlayerModel
            .find({
                eventId: new Types.ObjectId(eventId),
                playerId: { $ne: null as any, $exists: true }
            })
            .populate({
                path: 'playerId',
                match: { _id: { $ne: null } }
            })
            .exec()
            .then(docs => docs.filter(doc => doc.playerId != null));
    }

    async findOne(eventId: string, playerId: string): Promise<EventPlayer> {
        if (!Types.ObjectId.isValid(eventId) || !Types.ObjectId.isValid(playerId)) {
            throw new NotFoundException('Event-Player association not found');
        }

        const eventPlayer = await this.eventPlayerModel
            .findOne({
                eventId: new Types.ObjectId(eventId),
                playerId: new Types.ObjectId(playerId),
            })
            .populate('playerId')
            .exec();

        if (!eventPlayer) {
            throw new NotFoundException('Event-Player association not found');
        }

        return eventPlayer;
    }

    async findById(id: string): Promise<EventPlayer> {
        if (!Types.ObjectId.isValid(id)) {
            throw new NotFoundException(`EventPlayer with ID ${id} not found`);
        }

        const eventPlayer = await this.eventPlayerModel
            .findById(id)
            .populate('playerId')
            .populate('eventId')
            .exec();

        if (!eventPlayer) {
            throw new NotFoundException(`EventPlayer with ID ${id} not found`);
        }

        return eventPlayer;
    }

    async update(eventId: string, playerId: string, dto: UpdateEventPlayerDto): Promise<EventPlayer> {
        if (!Types.ObjectId.isValid(eventId) || !Types.ObjectId.isValid(playerId)) {
            throw new NotFoundException('Event-Player association not found');
        }

        const eventPlayer = await this.eventPlayerModel
            .findOneAndUpdate(
                {
                    eventId: new Types.ObjectId(eventId),
                    playerId: new Types.ObjectId(playerId),
                },
                dto,
                { new: true },
            )
            .populate('playerId')
            .exec();

        if (!eventPlayer) {
            throw new NotFoundException('Event-Player association not found');
        }

        return eventPlayer;
    }

    async removePlayerFromEvent(eventId: string, playerId: string): Promise<void> {
        if (!Types.ObjectId.isValid(eventId) || !Types.ObjectId.isValid(playerId)) {
            throw new NotFoundException('Event-Player association not found');
        }

        const result = await this.eventPlayerModel
            .findOneAndDelete({
                eventId: new Types.ObjectId(eventId),
                playerId: new Types.ObjectId(playerId),
            })
            .exec();

        if (!result) {
            throw new NotFoundException('Event-Player association not found');
        }
    }
}
