import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ timestamps: true })
export class Payroll extends Document {
  @Prop({ type: Types.ObjectId, ref: 'Employee', required: true })
  employeeId: Types.ObjectId;

  @Prop({ required: true })
  month: string;

  @Prop({ default: 0 })
  presentDays: number;

  @Prop({ default: 0 })
  absentDays: number;

  @Prop({ default: 0 })
  lateDays: number;

  @Prop({ default: 0 })
  halfDays: number;

  @Prop({ default: 0 })
  grossSalary: number;

  @Prop({ default: 0 })
  deduction: number;

  @Prop({ default: 0 })
  netSalary: number;

  @Prop({ default: 'draft', enum: ['draft', 'finalized'] })
  status: 'draft' | 'finalized';
}

export const PayrollSchema = SchemaFactory.createForClass(Payroll);
PayrollSchema.index({ employeeId: 1, month: 1 }, { unique: true });