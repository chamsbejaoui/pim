import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';
import { Role } from '../../common/enums/role.enum';
import { UserStatus } from '../../common/enums/user-status.enum';

export type UserDocument = HydratedDocument<User>;

@Schema({ collection: 'users', timestamps: true })
export class User {
  @Prop({ type: Types.ObjectId, ref: 'Club', required: false })
  clubId?: Types.ObjectId | null;

  @Prop({ required: true, unique: true, lowercase: true, trim: true })
  email: string;

  @Prop({ required: true })
  passwordHash: string;

  @Prop({ required: true })
  firstName: string;

  @Prop({ required: true })
  lastName: string;

  @Prop({ required: true })
  phone: string;

  @Prop()
  photoUrl?: string;

  @Prop({ type: String, enum: Role, required: true, index: true })
  role: Role;

  @Prop({ type: String, enum: UserStatus, required: true, index: true })
  status: UserStatus;

  @Prop()
  position?: string;

  @Prop()
  jobTitle?: string;

  @Prop({ default: true })
  isEmailVerified: boolean;
}

export const UserSchema = SchemaFactory.createForClass(User);

UserSchema.index({ clubId: 1, status: 1 });
UserSchema.index({ clubId: 1, role: 1 });
