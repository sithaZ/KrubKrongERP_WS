import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ timestamps: true })
export class Company extends Document {
  @Prop({ required: true, unique: true, trim: true, index: true })
  shopName: string;

  @Prop({ required: true, trim: true })
  ownerName: string;

  @Prop({ required: true, trim: true, lowercase: true })
  ownerEmail: string;

  @Prop({ trim: true })
  phone?: string;

  @Prop({ trim: true })
  address?: string;

  @Prop({ trim: true })
  businessType?: string;

  @Prop({ required: true, enum: ['active', 'inactive'], default: 'active' })
  status: 'active' | 'inactive';

  @Prop({ default: true })
  isActive: boolean;

  @Prop({ type: Types.ObjectId, ref: 'User', required: false, index: true })
  managerId?: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: false, index: true })
  createdByAdminId?: Types.ObjectId;
}

export const CompanySchema = SchemaFactory.createForClass(Company);
