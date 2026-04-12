import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export enum UserRole {
  ADMINISTRATEUR = 'Administrateur',
  RESPONSABLE_CLUB = 'Responsable du club',
  ENTRAINEUR = 'Entraîneur',
  SCOUT = 'Scout',
  COMPTABLE = 'Comptable',
  JOUEUR = 'Joueur',
}

export type UserDocument = User & Document;

@Schema({ timestamps: true })
export class User {
  @Prop({ required: true, unique: true })
  email: string;

  @Prop({ required: false })
  password: string;

  @Prop({ required: true })
  firstName: string;

  @Prop({ required: true })
  lastName: string;

  @Prop({
    type: String,
    enum: UserRole,
    default: UserRole.JOUEUR,
  })
  role: UserRole;

  @Prop({ default: false })
  isEmailVerified: boolean;

  @Prop({ required: false })
  emailVerificationToken: string;

  @Prop({ required: false })
  passwordResetToken: string;

  @Prop({ required: false })
  passwordResetExpires: Date;

  @Prop({ required: false })
  googleId: string;

  @Prop({ default: true })
  isActive: boolean;

  @Prop({ default: false })
  isApprovedByAdmin: boolean;

  createdAt: Date;
  updatedAt: Date;
}

export const UserSchema = SchemaFactory.createForClass(User);

// Create indexes
UserSchema.index({ email: 1 });
UserSchema.index({ googleId: 1 });
UserSchema.index({ emailVerificationToken: 1 });
UserSchema.index({ passwordResetToken: 1 });
