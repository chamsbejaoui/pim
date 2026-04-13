import 'reflect-metadata';
import { config as loadEnv } from 'dotenv';
import * as mongoose from 'mongoose';
import { Role } from '../common/enums/role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { hashValue } from '../common/utils/hash.util';
import { User, UserSchema } from '../users/schemas/user.schema';

async function run() {
  loadEnv();

  const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/odin_backend';
  const email = process.env.ADMIN_EMAIL;
  const password = process.env.ADMIN_PASSWORD;

  if (!email || !password) {
    throw new Error('ADMIN_EMAIL and ADMIN_PASSWORD are required');
  }

  await mongoose.connect(mongoUri);

  const userModel = mongoose.model(User.name, UserSchema);
  const existing = await userModel.findOne({ email: email.toLowerCase() });

  if (!existing) {
    const passwordHash = await hashValue(password);
    await userModel.create({
      clubId: null,
      email: email.toLowerCase(),
      passwordHash,
      firstName: 'Global',
      lastName: 'Admin',
      phone: '0000000000',
      role: Role.ADMIN,
      status: UserStatus.ACTIVE,
      isEmailVerified: true
    });
    // eslint-disable-next-line no-console
    console.log('Admin user created');
  } else {
    // eslint-disable-next-line no-console
    console.log('Admin user already exists');
  }

  await mongoose.disconnect();
}

run().catch(async (error) => {
  // eslint-disable-next-line no-console
  console.error(error);
  await mongoose.disconnect();
  process.exit(1);
});
