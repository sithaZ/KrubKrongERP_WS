import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ timestamps: true })
export class Employee extends Document {
  @Prop({ type: Types.ObjectId, ref: 'User', required: false })
  userId?: Types.ObjectId;

  @Prop({ required: true })
  fullName: string;

  @Prop({ trim: true, lowercase: true })
  email?: string;

  @Prop({ required: true, unique: true, trim: true })
  employeeCode: string;

  @Prop({ default: 'staff', trim: true })
  position: string;

  @Prop({ default: 'general', trim: true })
  department: string;

  @Prop({ required: true, enum: ['daily', 'monthly'] })
  salaryType: 'daily' | 'monthly';

  @Prop({ required: true, min: 0 })
  baseSalary: number;

  @Prop({ default: true })
  isActive: boolean;

  @Prop({ trim: true })
  phone?: string;

  @Prop()
  hireDate?: Date;
}

export const EmployeeSchema = SchemaFactory.createForClass(Employee);
