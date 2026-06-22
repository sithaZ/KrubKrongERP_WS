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

async function run() {
  const mongoUri = process.env.MONGO_URI;

  if (!mongoUri) {
    throw new Error('MONGO_URI is not set.');
  }

  await mongoose.connect(mongoUri);

  const companyModel: Model<CompanyDocument> = mongoose.model<CompanyDocument>(
    Company.name,
    CompanySchema,
  );
  const userModel: Model<UserDocument> = mongoose.model<UserDocument>(
    User.name,
    UserSchema,
  );

  const baiMak = await companyModel.findOne({ shopName: 'BaiMak' }).exec();

  if (!baiMak) {
    throw new Error('BaiMak company was not found.');
  }

  const managerFilter = {
    role: { $in: [Role.MANAGER, Role.MANAGER.toLowerCase()] },
  };

  const result = await userModel.updateMany(managerFilter, {
    $set: {
      companyId: baiMak._id,
      isActive: true,
      role: Role.MANAGER,
    },
  });

  const managers = await userModel
    .find(managerFilter, {
      email: 1,
      username: 1,
      role: 1,
      companyId: 1,
      name: 1,
      isActive: 1,
    })
    .sort({ email: 1 })
    .exec();

  console.log(
    JSON.stringify(
      {
        baiMakCompanyId: baiMak._id.toString(),
        matchedCount: result.matchedCount,
        modifiedCount: result.modifiedCount,
        managers: managers.map((manager) => ({
          id: manager._id.toString(),
          email: manager.email,
          username: manager.username,
          name: manager.name,
          role: manager.role,
          companyId: manager.companyId?.toString() || null,
          isActive: manager.isActive,
        })),
      },
      null,
      2,
    ),
  );
}

run()
  .catch((error) => {
    console.error('[assign-baimak-managers] Failed to reassign managers.');
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    if (mongoose.connection.readyState !== 0) {
      await mongoose.disconnect();
    }
  });
