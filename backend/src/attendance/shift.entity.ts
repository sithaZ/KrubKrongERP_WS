import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Shift extends Document {
  @Prop({ required: true, trim: true })
  shiftName: string;

  @Prop({ required: true, trim: true }) // format "HH:MM", e.g., "08:00"
  startTime: string;

  @Prop({ required: true, trim: true }) // format "HH:MM", e.g., "17:00"
  endTime: string;

  @Prop({ required: true, default: 15 })
  gracePeriodMinutes: number;

  @Prop({ required: true, default: 60 })
  breakMinutes: number;

  @Prop({ required: true, default: true })
  isActive: boolean;
}

export const ShiftSchema = SchemaFactory.createForClass(Shift);
