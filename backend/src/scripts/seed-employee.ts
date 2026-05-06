import * as bcrypt from 'bcrypt';
import * as dotenv from 'dotenv';
import mongoose, { Model, Types } from 'mongoose';
import { Company, CompanySchema } from '../companies/company.entity';
import { Role } from '../common/enums/role.enum';
import { normalizeRole } from '../common/utils/role.utils';
import { Employee, EmployeeSchema } from '../employees/employee.entity';
import { User, UserSchema } from '../users/user.entity';

dotenv.config();

type CompanyDocument = Company & {
  _id: Types.ObjectId;
};

type UserDocument = User & {
  _id: Types.ObjectId;
};

type EmployeeDocument = Employee & {
  _id: Types.ObjectId;
};

const REQUIRED_ENV_VARS = [
  'MONGO_URI',
  'COMPANY_NAME',
  'EMPLOYEE_USERNAME',
  'EMPLOYEE_EMAIL',
  'EMPLOYEE_PASSWORD',
  'EMPLOYEE_FULLNAME',
] as const;

const EMPLOYEE_CODE_PREFIX = 'EMP';
const EMPLOYEE_CODE_PAD_LENGTH = 3;

function getMissingEnvVars() {
  return REQUIRED_ENV_VARS.filter((key) => {
    const value = process.env[key];
    return !value || !value.trim();
  });
}

function formatEmployeeCode(sequence: number) {
  return `${EMPLOYEE_CODE_PREFIX}${sequence
    .toString()
    .padStart(EMPLOYEE_CODE_PAD_LENGTH, '0')}`;
}

async function getNextEmployeeCode(employeeModel: Model<EmployeeDocument>) {
  const [latestEmployee] = await employeeModel.aggregate<{ numericPart: number }>([
    {
      $match: {
        employeeCode: {
          $regex: `^${EMPLOYEE_CODE_PREFIX}[0-9]+$`,
        },
      },
    },
    {
      $addFields: {
        numericPart: {
          $toInt: {
            $substrCP: [
              '$employeeCode',
              EMPLOYEE_CODE_PREFIX.length,
              {
                $subtract: [
                  { $strLenCP: '$employeeCode' },
                  EMPLOYEE_CODE_PREFIX.length,
                ],
              },
            ],
          },
        },
      },
    },
    { $sort: { numericPart: -1 } },
    { $limit: 1 },
  ]);

  const nextSequence = (latestEmployee?.numericPart ?? 0) + 1;
  return formatEmployeeCode(nextSequence);
}

async function seedEmployee() {
  const missingEnvVars = getMissingEnvVars();

  if (missingEnvVars.length > 0) {
    console.error(
      `[seed-employee] Missing required environment variables: ${missingEnvVars.join(', ')}`,
    );
    process.exitCode = 1;
    return;
  }

  const mongoUri = process.env.MONGO_URI!;
  const companyName = process.env.COMPANY_NAME!.trim();
  const employeeUsername = process.env.EMPLOYEE_USERNAME!.trim();
  const employeeEmail = process.env.EMPLOYEE_EMAIL!.trim().toLowerCase();
  const employeePassword = process.env.EMPLOYEE_PASSWORD!;
  const employeeFullName = process.env.EMPLOYEE_FULLNAME!.trim();

  let companyModel: Model<CompanyDocument>;
  let userModel: Model<UserDocument>;
  let employeeModel: Model<EmployeeDocument>;

  try {
    console.log('[seed-employee] Connecting to MongoDB...');
    await mongoose.connect(mongoUri);

    companyModel = mongoose.model<CompanyDocument>(Company.name, CompanySchema);
    userModel = mongoose.model<UserDocument>(User.name, UserSchema);
    employeeModel = mongoose.model<EmployeeDocument>(Employee.name, EmployeeSchema);

    const company = await companyModel.findOne({ name: companyName });

    if (!company) {
      console.log(`[seed-employee] Company not found: ${companyName}`);
      process.exitCode = 1;
      return;
    }

    const manager = await userModel.findOne({
      companyId: company._id,
      role: {
        $in: [Role.MANAGER, 'manager'],
      },
    });

    if (!manager || normalizeRole(manager.role) !== Role.MANAGER) {
      console.log(
        `[seed-employee] Manager not found for company: ${company.name}`,
      );
      process.exitCode = 1;
      return;
    }

    const existingEmployee = await employeeModel
      .findOne({ email: employeeEmail })
      .populate('userId');

    if (existingEmployee) {
      if (
        existingEmployee.companyId?.toString() === company._id.toString() &&
        existingEmployee.userId
      ) {
        console.log(
          `[seed-employee] Employee already exists: ${employeeEmail}`,
        );
        return;
      }

      if (
        existingEmployee.companyId &&
        existingEmployee.companyId.toString() !== company._id.toString()
      ) {
        console.log(
          `[seed-employee] Employee already exists in another company: ${employeeEmail}`,
        );
        process.exitCode = 1;
        return;
      }
    }

    const existingUserByUsername = await userModel.findOne({
      username: employeeUsername,
    });
    const existingUserByEmail = await userModel.findOne({ email: employeeEmail });
    const existingUser = existingUserByEmail ?? existingUserByUsername;

    if (
      existingUserByUsername &&
      existingUserByUsername.email !== employeeEmail
    ) {
      console.log(
        `[seed-employee] Employee already exists: username "${employeeUsername}" is already in use.`,
      );
      process.exitCode = 1;
      return;
    }

    if (
      existingUser &&
      existingUser.companyId &&
      existingUser.companyId.toString() !== company._id.toString()
    ) {
      console.log(
        `[seed-employee] Employee already exists in another company: ${employeeEmail}`,
      );
      process.exitCode = 1;
      return;
    }

    if (existingUser && normalizeRole(existingUser.role) !== Role.EMPLOYEE) {
      console.log(
        `[seed-employee] Employee already exists: account "${existingUser.email}" is not an EMPLOYEE role.`,
      );
      process.exitCode = 1;
      return;
    }

    let employeeUser = existingUser;

    if (!employeeUser) {
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(employeePassword, salt);

      employeeUser = await userModel.create({
        username: employeeUsername,
        email: employeeEmail,
        password: hashedPassword,
        name: employeeFullName,
        role: Role.EMPLOYEE,
        companyId: company._id,
        isActive: true,
      });
    } else {
      const updatePayload: Partial<UserDocument> = {};

      if (!employeeUser.companyId) {
        updatePayload.companyId = company._id;
      }

      if (normalizeRole(employeeUser.role) !== Role.EMPLOYEE) {
        updatePayload.role = Role.EMPLOYEE;
      }

      if (employeeUser.name !== employeeFullName) {
        updatePayload.name = employeeFullName;
      }

      if (Object.keys(updatePayload).length > 0) {
        employeeUser = await userModel.findByIdAndUpdate(
          employeeUser._id,
          updatePayload,
          { new: true },
        );
      }

      if (!employeeUser) {
        console.error('[seed-employee] Failed to reload existing employee user.');
        process.exitCode = 1;
        return;
      }
    }

    if (existingEmployee) {
      const employeeUpdatePayload: Partial<EmployeeDocument> = {};

      if (!existingEmployee.userId) {
        employeeUpdatePayload.userId = employeeUser._id;
      }

      if (!existingEmployee.companyId) {
        employeeUpdatePayload.companyId = company._id;
      }

      if (existingEmployee.fullName !== employeeFullName) {
        employeeUpdatePayload.fullName = employeeFullName;
      }

      if (Object.keys(employeeUpdatePayload).length > 0) {
        await employeeModel.findByIdAndUpdate(existingEmployee._id, employeeUpdatePayload);
      }

      console.log(`[seed-employee] Employee already exists: ${employeeEmail}`);
      return;
    }

    const employeeCode = await getNextEmployeeCode(employeeModel);

    await employeeModel.create({
      userId: employeeUser._id,
      companyId: company._id,
      fullName: employeeFullName,
      email: employeeEmail,
      employeeCode,
      position: 'staff',
      department: 'general',
      salaryType: 'monthly',
      baseSalary: 0,
      isActive: true,
      hireDate: new Date(),
    });

    console.log(
      `[seed-employee] Employee created: ${employeeEmail} -> company ${company.name}`,
    );
  } catch (error) {
    console.error('[seed-employee] Failed to seed employee data.');
    console.error(error);
    process.exitCode = 1;
  } finally {
    if (mongoose.connection.readyState !== 0) {
      await mongoose.connection.close();
      console.log('[seed-employee] MongoDB connection closed.');
    }
  }
}

void seedEmployee();
