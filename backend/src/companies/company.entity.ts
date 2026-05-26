import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ timestamps: true })
export class Company extends Document {
  static readonly DEFAULT_SUBSCRIPTION_PRICE = 50;

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

  @Prop({ trim: true })
  description?: string;

  @Prop({ trim: true })
  whatTheySell?: string;

  @Prop({ trim: true })
  provinceOrCity?: string;

  @Prop({ required: true, enum: ['active', 'inactive'], default: 'active' })
  status: 'active' | 'inactive';

  @Prop({ default: true })
  isActive: boolean;

  @Prop({
    required: true,
    enum: ['Trial', 'Active', 'Expired', 'Suspended'],
    default: 'Trial',
  })
  subscriptionStatus: 'Trial' | 'Active' | 'Expired' | 'Suspended';

  @Prop({ default: Company.DEFAULT_SUBSCRIPTION_PRICE })
  subscriptionPrice: number;

  @Prop()
  subscriptionStartDate?: Date;

  @Prop()
  subscriptionEndDate?: Date;

  @Prop()
  nextRenewalDate?: Date;

  @Prop({ type: Types.ObjectId, ref: 'User', required: false, index: true })
  ownerId?: Types.ObjectId;

  // Legacy alias kept during migration. It mirrors ownerId in responses.
  @Prop({ type: Types.ObjectId, ref: 'User', required: false, index: true })
  managerId?: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: false, index: true })
  createdByAdminId?: Types.ObjectId;
}

export const CompanySchema = SchemaFactory.createForClass(Company);
