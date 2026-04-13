import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { User, UserDocument, UserRole } from './entities/user.entity';
import * as bcrypt from 'bcrypt';
import { generateSixDigitCode } from '../utils/code-generator';

@Injectable()
export class UserService {
  constructor(
    @InjectModel(User.name)
    private userModel: Model<UserDocument>,
  ) { }

  async create(userData: Partial<User>): Promise<UserDocument> {
    if (userData.password) {
      userData.password = await bcrypt.hash(userData.password, 10);
    }
    const user = new this.userModel(userData);
    return user.save();
  }

  async findByEmail(email: string): Promise<UserDocument | null> {
    return this.userModel.findOne({ email }).exec();
  }

  async findById(id: string): Promise<UserDocument | null> {
    if (!id || !Types.ObjectId.isValid(id)) {
      return null;
    }
    return this.userModel.findById(id).exec();
  }

  async findByGoogleId(googleId: string): Promise<UserDocument | null> {
    return this.userModel.findOne({ googleId }).exec();
  }

  async update(id: string, updateData: Partial<User>): Promise<UserDocument> {
    if (!id || !Types.ObjectId.isValid(id)) {
      throw new NotFoundException('User not found');
    }
    if (updateData.password) {
      updateData.password = await bcrypt.hash(updateData.password, 10);
    }
    const user = await this.userModel
      .findByIdAndUpdate(id, updateData, { new: true })
      .exec();
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return user;
  }

  async verifyEmail(code: string): Promise<UserDocument> {
    const user = await this.userModel.findOne({
      emailVerificationToken: code,
    }).exec();

    if (!user) {
      throw new NotFoundException('Invalid verification code');
    }

    user.isEmailVerified = true;
    user.emailVerificationToken = null;
    return user.save();
  }

  async setPasswordResetToken(email: string): Promise<string> {
    const user = await this.findByEmail(email);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const resetCode = generateSixDigitCode();
    const resetExpires = new Date();
    resetExpires.setHours(resetExpires.getHours() + 1); // Code valid for 1 hour

    user.passwordResetToken = resetCode;
    user.passwordResetExpires = resetExpires;
    await user.save();

    return resetCode;
  }

  async resetPassword(code: string, newPassword: string): Promise<UserDocument> {
    const user = await this.userModel.findOne({
      passwordResetToken: code,
    }).exec();

    if (!user || !user.passwordResetExpires || user.passwordResetExpires < new Date()) {
      throw new NotFoundException('Invalid or expired reset code');
    }

    user.password = await bcrypt.hash(newPassword, 10);
    user.passwordResetToken = null;
    user.passwordResetExpires = null;
    return user.save();
  }

  async validatePassword(user: UserDocument, password: string): Promise<boolean> {
    if (!user.password) {
      return false;
    }
    return bcrypt.compare(password, user.password);
  }

  async findPendingUsers(): Promise<UserDocument[]> {
    return this.userModel
      .find({
        isEmailVerified: true,
        isApprovedByAdmin: false,
        isActive: false,
      })
      .exec();
  }

  async approveUser(id: string): Promise<UserDocument> {
    if (!id || !Types.ObjectId.isValid(id)) {
      throw new NotFoundException('User not found');
    }
    const user = await this.userModel.findByIdAndUpdate(
      id,
      {
        isApprovedByAdmin: true,
        isActive: true,
      },
      { new: true },
    ).exec();

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async rejectUser(id: string): Promise<UserDocument> {
    if (!id || !Types.ObjectId.isValid(id)) {
      throw new NotFoundException('User not found');
    }
    const user = await this.userModel.findByIdAndUpdate(
      id,
      {
        isApprovedByAdmin: false,
        isActive: false,
      },
      { new: true },
    ).exec();

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async findAll(): Promise<UserDocument[]> {
    return this.userModel.find().exec();
  }
}
