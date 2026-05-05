import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Company extends Document {
  @Prop({ required: true, unique: true, trim: true, index: true })
  name: string;

  @Prop({ default: true })
  isActive: boolean;
}

export const CompanySchema = SchemaFactory.createForClass(Company);
