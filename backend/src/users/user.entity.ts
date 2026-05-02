import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { Role } from '../common/enums/role.enum';

export enum UserRole {
  ADMIN = 'admin',
  CASHIER = 'cashier',
  MANAGER = 'manager',
}

@Schema({ timestamps: true })
export class User extends Document {
  @Prop({ required: true, unique: true })
  username: string;

  @Prop({ required: true, unique: true })
  email: string;

  @Prop({ required: true })
  password: string;

<<<<<<< HEAD
  @Prop({ required: true })
  name: string;

  @Prop({ required: false })
  phone?: string;

  @Prop({ required: false })
  avatar?: string;

  @Prop({ enum: UserRole, default: UserRole.CASHIER })
  role: UserRole;

=======
  @Prop({ required: true, enum: Object.values(Role), default: Role.STAFF })
  role: string;

>>>>>>> 90061212bc30cab3665bd0cf20465d9da5a273ef
  @Prop({ default: true })
  isActive: boolean;
}

export const UserSchema = SchemaFactory.createForClass(User);
