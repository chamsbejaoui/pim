import 'reflect-metadata';
import { config as loadEnv } from 'dotenv';
import * as mongoose from 'mongoose';
import { Types } from 'mongoose';
import { Role } from '../common/enums/role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { ClubStatus } from '../common/enums/club-status.enum';
import { hashValue } from '../common/utils/hash.util';
import { User, UserSchema } from '../users/schemas/user.schema';
import { Club, ClubSchema } from '../clubs/schemas/club.schema';

const POSITIONS = ['GK', 'CB', 'LB', 'RB', 'DM', 'CM', 'AM', 'LW', 'RW', 'ST'];

async function getOrCreateAdmin(userModel: mongoose.Model<User>) {
  const envEmail = process.env.ADMIN_EMAIL?.toLowerCase();
  const envPassword = process.env.ADMIN_PASSWORD;

  if (envEmail) {
    let admin = await userModel.findOne({ email: envEmail });
    if (!admin) {
      if (!envPassword) {
        throw new Error('ADMIN_PASSWORD is required to create the admin user');
      }
      const passwordHash = await hashValue(envPassword);
      admin = await userModel.create({
        clubId: null,
        email: envEmail,
        passwordHash,
        firstName: 'Global',
        lastName: 'Admin',
        phone: '0000000000',
        role: Role.ADMIN,
        status: UserStatus.ACTIVE,
        isEmailVerified: true,
        isActive: true,
        isApprovedByAdmin: true
      });
    }
    return admin;
  }

  const existingAdmin = await userModel.findOne({ role: Role.ADMIN });
  if (existingAdmin) return existingAdmin;

  const responsable = await userModel.findOne({ role: Role.CLUB_RESPONSABLE });
  if (responsable) return responsable;

  throw new Error(
    'No admin or responsable user found. Set ADMIN_EMAIL and ADMIN_PASSWORD in .env to create one.'
  );
}

async function run() {
  loadEnv();

  const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/odin_backend';
  const clubName = (process.env.SEED_CLUB_NAME || 'realmadrid').trim();
  const league = process.env.SEED_CLUB_LEAGUE || 'La Liga';
  const country = process.env.SEED_CLUB_COUNTRY || 'Spain';
  const city = process.env.SEED_CLUB_CITY || 'Madrid';
  const count = Number(process.env.SEED_PLAYER_COUNT || 20);
  const playerPassword = process.env.SEED_PLAYER_PASSWORD || 'Player12345!';

  await mongoose.connect(mongoUri);

  const userModel = mongoose.model(User.name, UserSchema);
  const clubModel = mongoose.model(Club.name, ClubSchema);

  const adminUser = await getOrCreateAdmin(userModel);

  let club = await clubModel.findOne({ name: new RegExp(`^${clubName}$`, 'i') });
  if (!club) {
    club = await clubModel.create({
      name: clubName,
      league,
      country,
      city,
      status: ClubStatus.ACTIVE,
      createdByUserId: new Types.ObjectId(adminUser.id)
    });
  } else if (club.status !== ClubStatus.ACTIVE) {
    club.status = ClubStatus.ACTIVE;
    await club.save();
  }

  const passwordHash = await hashValue(playerPassword);
  let created = 0;
  let updated = 0;

  for (let i = 1; i <= count; i += 1) {
    const index = String(i).padStart(2, '0');
    const email = `player${index}@${clubName.toLowerCase()}.local`;
    const firstName = `Player`;
    const lastName = index;
    const position = POSITIONS[(i - 1) % POSITIONS.length];

    const existing = await userModel.findOne({ email });
    if (!existing) {
      await userModel.create({
        clubId: club._id,
        email,
        passwordHash,
        firstName,
        lastName,
        phone: `+3400000${index}`,
        role: Role.JOUEUR,
        status: UserStatus.ACTIVE,
        position,
        isEmailVerified: true,
        isActive: true,
        isApprovedByAdmin: true
      });
      created += 1;
    } else {
      existing.clubId = club._id as Types.ObjectId;
      existing.firstName = firstName;
      existing.lastName = lastName;
      existing.role = Role.JOUEUR;
      existing.status = UserStatus.ACTIVE;
      existing.position = position;
      existing.isEmailVerified = true;
      existing.isActive = true;
      existing.isApprovedByAdmin = true;
      if (!existing.passwordHash) {
        existing.passwordHash = passwordHash;
      }
      await existing.save();
      updated += 1;
    }
  }

  // eslint-disable-next-line no-console
  console.log(
    `Seed complete. Club: ${club.name} (${club.status}). Players created: ${created}, updated: ${updated}. Password: ${playerPassword}`
  );

  await mongoose.disconnect();
}

run().catch(async (error) => {
  // eslint-disable-next-line no-console
  console.error(error);
  await mongoose.disconnect();
  process.exit(1);
});
