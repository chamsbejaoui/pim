import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { OtpService } from './otp.service';
import { OtpCode, OtpCodeSchema } from './schemas/otp-code.schema';

@Module({
  imports: [MongooseModule.forFeature([{ name: OtpCode.name, schema: OtpCodeSchema }])],
  providers: [OtpService],
  exports: [OtpService]
})
export class OtpModule {}
