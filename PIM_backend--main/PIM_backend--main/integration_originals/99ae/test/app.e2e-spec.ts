import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import * as request from 'supertest';
import { MongoMemoryServer } from 'mongodb-memory-server';
import * as mongoose from 'mongoose';
import { AppModule } from '../src/app.module';
import { ClubStatus } from '../src/common/enums/club-status.enum';
import { Role } from '../src/common/enums/role.enum';
import { UserStatus } from '../src/common/enums/user-status.enum';
import { hashValue } from '../src/common/utils/hash.util';
import { Club } from '../src/clubs/schemas/club.schema';
import { User } from '../src/users/schemas/user.schema';

describe('App (e2e)', () => {
  let app: INestApplication;
  let mongoServer: MongoMemoryServer;
  let userModel: mongoose.Model<User>;
  let clubModel: mongoose.Model<Club>;

  beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    process.env.MONGO_URI = mongoServer.getUri();
    process.env.JWT_SECRET = 'test_secret';
    process.env.JWT_EXPIRES_IN = '1d';

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule]
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api');
    await app.init();

    userModel = moduleFixture.get(getModelToken(User.name));
    clubModel = moduleFixture.get(getModelToken(Club.name));

    await userModel.create({
      email: 'admin@odin.local',
      passwordHash: await hashValue('Admin123!'),
      firstName: 'Admin',
      lastName: 'Root',
      phone: '0000000000',
      role: Role.ADMIN,
      status: UserStatus.ACTIVE,
      isEmailVerified: true,
      clubId: null
    });
  });

  afterAll(async () => {
    await app.close();
    await mongoose.disconnect();
    await mongoServer.stop();
  });

  it('register responsable -> admin approve -> register player -> responsable approve -> player can access', async () => {
    const registerResponsableRes = await request(app.getHttpServer())
      .post('/api/auth/register/responsable')
      .send({
        clubName: 'Club One',
        league: 'League A',
        firstName: 'Responsable',
        lastName: 'One',
        phone: '1111111111',
        email: 'responsable1@club.local',
        password: 'Password123!'
      })
      .expect(201);

    const clubId = registerResponsableRes.body.clubId as string;

    await userModel.updateOne(
      { email: 'responsable1@club.local' },
      { $set: { isEmailVerified: true } }
    );

    const adminLogin = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ email: 'admin@odin.local', password: 'Admin123!' })
      .expect(201);

    const adminToken = adminLogin.body.accessToken as string;

    await request(app.getHttpServer())
      .patch(`/api/clubs/${clubId}/approval`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ status: ClubStatus.ACTIVE })
      .expect(200);

    const responsableLogin = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ email: 'responsable1@club.local', password: 'Password123!' })
      .expect(201);

    const responsableToken = responsableLogin.body.accessToken as string;

    const registerPlayerRes = await request(app.getHttpServer())
      .post('/api/auth/register/member')
      .send({
        firstName: 'Player',
        lastName: 'One',
        phone: '2222222222',
        email: 'player1@club.local',
        password: 'Player123!',
        role: Role.JOUEUR,
        clubId,
        position: 'CM'
      })
      .expect(201);

    const playerId = registerPlayerRes.body.userId as string;

    await userModel.updateOne({ email: 'player1@club.local' }, { $set: { isEmailVerified: true } });

    await request(app.getHttpServer())
      .patch(`/api/users/${playerId}/approval`)
      .set('Authorization', `Bearer ${responsableToken}`)
      .send({ status: UserStatus.ACTIVE })
      .expect(200);

    const playerLogin = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ email: 'player1@club.local', password: 'Player123!' })
      .expect(201);

    const playerToken = playerLogin.body.accessToken as string;

    await request(app.getHttpServer())
      .get('/api/users/me')
      .set('Authorization', `Bearer ${playerToken}`)
      .expect(200);

    const secondClub = await clubModel.create({
      name: 'Club Two',
      league: 'League B',
      status: ClubStatus.ACTIVE,
      createdByUserId: new mongoose.Types.ObjectId(),
      responsableUserId: new mongoose.Types.ObjectId()
    });

    const foreignUser = await userModel.create({
      email: 'foreign@club.local',
      passwordHash: await hashValue('Foreign123!'),
      firstName: 'Foreign',
      lastName: 'User',
      phone: '3333333333',
      role: Role.JOUEUR,
      status: UserStatus.PENDING_CLUB_APPROVAL,
      isEmailVerified: true,
      clubId: secondClub._id,
      position: 'ST'
    });

    await request(app.getHttpServer())
      .patch(`/api/users/${String(foreignUser._id)}/approval`)
      .set('Authorization', `Bearer ${responsableToken}`)
      .send({ status: UserStatus.ACTIVE })
      .expect(403);
  });

  it('sensitive action requires re-auth for payroll execute', async () => {
    const club = await clubModel.create({
      name: 'Club Finance',
      league: 'League F',
      status: ClubStatus.ACTIVE,
      createdByUserId: new mongoose.Types.ObjectId(),
      responsableUserId: new mongoose.Types.ObjectId()
    });

    await userModel.create({
      email: 'financier@club.local',
      passwordHash: await hashValue('Financier123!'),
      firstName: 'Fin',
      lastName: 'Ops',
      phone: '4444444444',
      role: Role.FINANCIER,
      status: UserStatus.ACTIVE,
      isEmailVerified: true,
      clubId: club._id
    });

    const login = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ email: 'financier@club.local', password: 'Financier123!' })
      .expect(201);

    const token = login.body.accessToken as string;

    await request(app.getHttpServer())
      .post('/api/finance/payroll/execute')
      .set('Authorization', `Bearer ${token}`)
      .send({ periodStart: '2026-01-01', periodEnd: '2026-01-31' })
      .expect(403);

    await request(app.getHttpServer())
      .post('/api/finance/payroll/execute')
      .set('Authorization', `Bearer ${token}`)
      .set('x-sensitive-password', 'Financier123!')
      .send({ periodStart: '2026-01-01', periodEnd: '2026-01-31' })
      .expect(201);
  });

  it('blocks cross-club chat access and only lists same-club chat users', async () => {
    const clubA = await clubModel.create({
      name: 'Club Chat A',
      league: 'League C1',
      status: ClubStatus.ACTIVE,
      createdByUserId: new mongoose.Types.ObjectId(),
      responsableUserId: new mongoose.Types.ObjectId()
    });
    const clubB = await clubModel.create({
      name: 'Club Chat B',
      league: 'League C2',
      status: ClubStatus.ACTIVE,
      createdByUserId: new mongoose.Types.ObjectId(),
      responsableUserId: new mongoose.Types.ObjectId()
    });

    await userModel.create([
      {
        email: 'coach-chat-a@club.local',
        passwordHash: await hashValue('Coach123!'),
        firstName: 'Coach',
        lastName: 'A',
        phone: '5550000001',
        role: Role.STAFF_TECHNIQUE,
        status: UserStatus.ACTIVE,
        isEmailVerified: true,
        clubId: clubA._id
      },
      {
        email: 'player-chat-a@club.local',
        passwordHash: await hashValue('PlayerA123!'),
        firstName: 'Player',
        lastName: 'A',
        phone: '5550000002',
        role: Role.JOUEUR,
        status: UserStatus.ACTIVE,
        isEmailVerified: true,
        clubId: clubA._id
      },
      {
        email: 'player-chat-b@club.local',
        passwordHash: await hashValue('PlayerB123!'),
        firstName: 'Player',
        lastName: 'B',
        phone: '5550000003',
        role: Role.JOUEUR,
        status: UserStatus.ACTIVE,
        isEmailVerified: true,
        clubId: clubB._id
      }
    ]);

    const coachLogin = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ email: 'coach-chat-a@club.local', password: 'Coach123!' })
      .expect(201);
    const coachToken = coachLogin.body.accessToken as string;

    const playerALogin = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ email: 'player-chat-a@club.local', password: 'PlayerA123!' })
      .expect(201);
    const playerAToken = playerALogin.body.accessToken as string;

    const playerBLogin = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ email: 'player-chat-b@club.local', password: 'PlayerB123!' })
      .expect(201);
    const playerBToken = playerBLogin.body.accessToken as string;

    const usersResponse = await request(app.getHttpServer())
      .get('/api/chat/users')
      .set('Authorization', `Bearer ${coachToken}`)
      .expect(200);

    const listedUsers = usersResponse.body as Array<Record<string, unknown>>;
    expect(listedUsers.some((u) => u.email === 'player-chat-a@club.local')).toBe(true);
    expect(listedUsers.some((u) => u.email === 'player-chat-b@club.local')).toBe(false);

    const playerARecord = await userModel.findOne({ email: 'player-chat-a@club.local' });
    const playerBRecord = await userModel.findOne({ email: 'player-chat-b@club.local' });

    const directConversation = await request(app.getHttpServer())
      .post('/api/chat/conversations/direct')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ targetUserId: String(playerARecord?._id) })
      .expect(201);

    await request(app.getHttpServer())
      .post('/api/chat/conversations/direct')
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ targetUserId: String(playerBRecord?._id) })
      .expect(403);

    await request(app.getHttpServer())
      .post(`/api/chat/conversations/${directConversation.body._id}/messages`)
      .set('Authorization', `Bearer ${coachToken}`)
      .send({ text: 'Training session at 08:00' })
      .expect(201);

    const notifA = await request(app.getHttpServer())
      .get('/api/notifications?unreadOnly=true')
      .set('Authorization', `Bearer ${playerAToken}`)
      .expect(200);
    expect(notifA.body.length).toBeGreaterThanOrEqual(1);

    const notifB = await request(app.getHttpServer())
      .get('/api/notifications?unreadOnly=true')
      .set('Authorization', `Bearer ${playerBToken}`)
      .expect(200);
    expect(notifB.body.length).toBe(0);
  });
});
