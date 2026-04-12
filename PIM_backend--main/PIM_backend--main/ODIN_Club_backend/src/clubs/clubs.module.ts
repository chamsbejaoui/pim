import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuditModule } from '../audit/audit.module';
import { User, UserSchema } from '../users/schemas/user.schema';
import { ClubsController } from './clubs.controller';
import { ClubsService } from './clubs.service';
import { Club, ClubSchema } from './schemas/club.schema';

@Module({
  imports: [
    AuditModule,
    MongooseModule.forFeature([
      { name: Club.name, schema: ClubSchema },
      { name: User.name, schema: UserSchema }
    ])
  ],
  controllers: [ClubsController],
  providers: [ClubsService],
  exports: [ClubsService, MongooseModule]
})
export class ClubsModule {}
