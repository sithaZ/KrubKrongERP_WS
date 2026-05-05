import * as bcrypt from 'bcrypt';
import * as dotenv from 'dotenv';
import mongoose, { Model, Types } from 'mongoose';
import { Company, CompanySchema } from '../companies/company.entity';
import { Role } from '../common/enums/role.enum';
import { User, UserSchema } from '../users/user.entity';

dotenv.config();

type CompanyDocument = Company & {
  _id: Types.ObjectId;
};

type UserDocument = User & {
  _id: Types.ObjectId;
};

const REQUIRED_ENV_VARS = [
  'MONGO_URI',
  'MANAGER_USERNAME',
  'MANAGER_EMAIL',
  'MANAGER_PASSWORD',
  'COMPANY_NAME',
] as const;

function getMissingEnvVars() {
  return REQUIRED_ENV_VARS.filter((key) => {
    const value = process.env[key];
    return !value || !value.trim();
  });
}

async function seedManager() {
  const missingEnvVars = getMissingEnvVars();

  if (missingEnvVars.length > 0) {
    console.error(
      `[seed-manager] Missing required environment variables: ${missingEnvVars.join(', ')}`,
    );
    process.exitCode = 1;
    return;
  }

  const mongoUri = process.env.MONGO_URI!;
  const companyName = process.env.COMPANY_NAME!.trim();
  const managerUsername = process.env.MANAGER_USERNAME!.trim();
  const managerEmail = process.env.MANAGER_EMAIL!.trim().toLowerCase();
  const managerPassword = process.env.MANAGER_PASSWORD!;

  let companyModel: Model<CompanyDocument>;
  let userModel: Model<UserDocument>;

  try {
    console.log('[seed-manager] Connecting to MongoDB...');
    await mongoose.connect(mongoUri);

    companyModel = mongoose.model<CompanyDocument>(Company.name, CompanySchema);
    userModel = mongoose.model<UserDocument>(User.name, UserSchema);

    let company = await companyModel.findOne({ name: companyName });

    if (company) {
      console.log(
        `[seed-manager] Company already exists: ${company.name} (${company._id.toString()})`,
      );
    } else {
      company = await companyModel.create({
        name: companyName,
        isActive: true,
      });
      console.log(
        `[seed-manager] Company created: ${company.name} (${company._id.toString()})`,
      );
    }

    const existingManager = await userModel.findOne({
      $or: [{ username: managerUsername }, { email: managerEmail }],
    });

    if (existingManager) {
      console.log(
        `[seed-manager] Manager already exists: ${existingManager.email}. No duplicate manager was created.`,
      );

      if (!existingManager.companyId) {
        existingManager.companyId = company._id;
        existingManager.role = Role.MANAGER;
        await existingManager.save();
        console.log(
          `[seed-manager] Existing manager linked to company: ${company.name}`,
        );
      }

      return;
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(managerPassword, salt);

    const manager = await userModel.create({
      username: managerUsername,
      email: managerEmail,
      password: hashedPassword,
      name: managerUsername,
      role: Role.MANAGER,
      companyId: company._id,
      isActive: true,
    });

    console.log(
      `[seed-manager] Manager created: ${manager.email} -> company ${company.name}`,
    );
  } catch (error) {
    console.error('[seed-manager] Failed to seed manager/company data.');
    console.error(error);
    process.exitCode = 1;
  } finally {
    if (mongoose.connection.readyState !== 0) {
      await mongoose.connection.close();
      console.log('[seed-manager] MongoDB connection closed.');
    }
  }
}

void seedManager();
