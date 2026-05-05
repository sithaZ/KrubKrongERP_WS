import * as bcrypt from 'bcrypt';
import * as dotenv from 'dotenv';
import mongoose, { Model, Types } from 'mongoose';
import { User, UserSchema } from '../users/user.entity';
import { Role } from '../common/enums/role.enum';
import { normalizeRole } from '../common/utils/role.utils';

dotenv.config();

type UserDocument = User & {
  _id: Types.ObjectId;
};

const REQUIRED_ENV_VARS = [
  'MONGO_URI',
  'ADMIN_USERNAME',
  'ADMIN_EMAIL',
  'ADMIN_PASSWORD',
] as const;

function getMissingEnvVars() {
  return REQUIRED_ENV_VARS.filter((key) => {
    const value = process.env[key];
    return !value || !value.trim();
  });
}

async function seedAdmin() {
  const missingEnvVars = getMissingEnvVars();

  if (missingEnvVars.length > 0) {
    console.error(
      `[seed-admin] Missing required environment variables: ${missingEnvVars.join(', ')}`,
    );
    process.exitCode = 1;
    return;
  }

  const mongoUri = process.env.MONGO_URI!;
  const adminUsername = process.env.ADMIN_USERNAME!.trim();
  const adminEmail = process.env.ADMIN_EMAIL!.trim().toLowerCase();
  const adminPassword = process.env.ADMIN_PASSWORD!;

  let userModel: Model<UserDocument>;

  try {
    console.log('[seed-admin] Connecting to MongoDB...');
    await mongoose.connect(mongoUri);

    userModel = mongoose.model<UserDocument>(User.name, UserSchema);

    const existingAdmin = await userModel.findOne({
      role: {
        $in: [Role.ADMIN, 'admin'],
      },
    });

    if (existingAdmin && normalizeRole(existingAdmin.role) === Role.ADMIN) {
      console.log(
        `[seed-admin] ADMIN already exists: ${existingAdmin.email}. No new admin was created.`,
      );
      return;
    }

    const existingUsername = await userModel.findOne({ username: adminUsername });
    if (existingUsername) {
      console.error(
        `[seed-admin] Cannot create ADMIN. Username "${adminUsername}" is already in use.`,
      );
      process.exitCode = 1;
      return;
    }

    const existingEmail = await userModel.findOne({ email: adminEmail });
    if (existingEmail) {
      console.error(
        `[seed-admin] Cannot create ADMIN. Email "${adminEmail}" is already in use.`,
      );
      process.exitCode = 1;
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(adminPassword, salt);

    const admin = await userModel.create({
      username: adminUsername,
      email: adminEmail,
      password: hashedPassword,
      name: adminUsername,
      role: Role.ADMIN,
      isActive: true,
    });

    console.log(
      `[seed-admin] ADMIN user created successfully with email: ${admin.email}`,
    );
  } catch (error) {
    console.error('[seed-admin] Failed to seed ADMIN user.');
    console.error(error);
    process.exitCode = 1;
  } finally {
    if (mongoose.connection.readyState !== 0) {
      await mongoose.connection.close();
      console.log('[seed-admin] MongoDB connection closed.');
    }
  }
}

void seedAdmin();
