import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { AiModule } from './ai/ai.module';
import { AnalysisModule } from './analysis/analysis.module';
import { AuditModule } from './audit/audit.module';
import { AuthModule } from './auth/auth.module';
import { ChatModule } from './chat/chat.module';
import { ClubsModule } from './clubs/clubs.module';
import { EmailModule } from './email/email.module';
import { FinanceModule } from './finance/finance.module';
import { IngestionModule } from './ingestion/ingestion.module';
import { MatchesModule } from './matches/matches.module';
import { MedicalModule } from './medical/medical.module';
import { NotificationsModule } from './notifications/notifications.module';
import { OtpModule } from './otp/otp.module';
import { PlayersModule } from './players/players.module';
import { ProvidersModule } from './providers/providers.module';
import { RbacModule } from './rbac/rbac.module';
import { RealtimeModule } from './realtime/realtime.module';
import { ReportsModule as AiReportsModule } from './reports/reports.module';
import { SimulationModule } from './simulation/simulation.module';
import { SportsPerformanceModule } from './sports-performance/sports-performance.module';
import { UserModule } from './user/user.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        uri: configService.get<string>('MONGODB_URI') || 'mongodb://localhost:27017/odin_club',
      }),
      inject: [ConfigService],
    }),
    RbacModule,
    RealtimeModule,
    OtpModule,
    AnalysisModule,
    AuditModule,
    UsersModule,
    ClubsModule,
    AuthModule,
    UserModule,
    EmailModule,
    FinanceModule,
    NotificationsModule,
    ChatModule,
    PlayersModule,
    MatchesModule,
    ProvidersModule,
    IngestionModule,
    MedicalModule,
    AiModule,
    AiReportsModule,
    SimulationModule,
    SportsPerformanceModule,
  ],
})
export class AppModule { }
