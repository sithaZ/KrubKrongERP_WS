import mongoose, { Model, Types } from 'mongoose';
import * as dotenv from 'dotenv';
import { Company, CompanySchema } from '../companies/company.entity';
import { User, UserSchema } from '../users/user.entity';
import { Role } from '../common/enums/role.enum';

dotenv.config();

type CompanyDocument = Company & {
  _id: Types.ObjectId;
};

type UserDocument = User & {
  _id: Types.ObjectId;
};

async function run() {
  const mongoUri = process.env.MONGO_URI;
  if (!mongoUri) {
    console.error('[migrate-owners] MONGO_URI is not set.');
    process.exitCode = 1;
    return;
  }

  console.log('[migrate-owners] Connecting to MongoDB...');
  await mongoose.connect(mongoUri);

  try {
    const companyModel: Model<CompanyDocument> = mongoose.model(
      Company.name,
      CompanySchema,
    );
    const userModel: Model<UserDocument> = mongoose.model(User.name, UserSchema);

    const companies = await companyModel.find({}).exec();
    let updatedShops = 0;
    let updatedUsers = 0;

    for (const company of companies) {
      const legacyOwnerId = company.ownerId || company.managerId;

      if (!legacyOwnerId) {
        continue;
      }

      const ownerUser = await userModel.findById(legacyOwnerId).exec();

      if (!ownerUser) {
        console.warn(
          `[migrate-owners] Shop "${company.shopName}" references missing user ${legacyOwnerId.toString()}.`,
        );
        continue;
      }

      let changed = false;

      if (!company.ownerId || company.ownerId.toString() !== ownerUser._id.toString()) {
        company.ownerId = ownerUser._id as Types.ObjectId;
        changed = true;
      }

      if (!company.managerId || company.managerId.toString() !== ownerUser._id.toString()) {
        company.managerId = ownerUser._id as Types.ObjectId;
        changed = true;
      }

      if (changed) {
        await company.save();
        updatedShops++;
      }

      if (ownerUser.role !== Role.OWNER) {
        ownerUser.role = Role.OWNER;
        ownerUser.companyId = company._id as Types.ObjectId;
        await ownerUser.save();
        updatedUsers++;
      }
    }

    console.log(
      `[migrate-owners] Migration complete. Updated ${updatedShops} shops and ${updatedUsers} owner accounts.`,
    );
  } catch (error) {
    console.error('[migrate-owners] Migration failed:', error);
    process.exitCode = 1;
  } finally {
    await mongoose.connection.close();
    console.log('[migrate-owners] Connection closed.');
  }
}

void run();
