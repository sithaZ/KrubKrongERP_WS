import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ timestamps: true })
export class Attendance extends Document {
  @Prop({ type: Types.ObjectId, ref: 'Employee', required: true })
  employeeId: Types.ObjectId;

  @Prop({ required: true })
  workDate: string;

  @Prop()
  checkIn?: Date;

  @Prop()
  checkOut?: Date;

  @Prop({
    required: true,
    enum: ['present', 'absent', 'late', 'half_day'],
    default: 'present',
  })
  status: 'present' | 'absent' | 'late' | 'half_day';

  @Prop({ default: 0 })
  workedHours: number;

  @Prop({ default: '' })
  note: string;
}

export const AttendanceSchema = SchemaFactory.createForClass(Attendance);
AttendanceSchema.index({ employeeId: 1, workDate: 1 }, { unique: true });