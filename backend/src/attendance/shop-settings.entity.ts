import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ timestamps: true })
export class ShopSettings extends Document {
  @Prop({ required: true })
  shopName: string;

  @Prop({ type: Types.ObjectId, ref: 'Company', required: false, index: true })
  companyId?: Types.ObjectId;

  @Prop({ type: Object, required: true })
  coordinates: {
    lat: number;
    lng: number;
  };

  @Prop({ required: true, default: 50 })
  radius: number; // in meters

  @Prop({ required: true })
  secretKey: string;

  @Prop({ required: true })
  ownerId: string;

  @Prop({ default: false })
  allowManagerSelfAttendance: boolean;

  @Prop({ default: false })
  allowStaffSelfAttendance: boolean;
}

export const ShopSettingsSchema = SchemaFactory.createForClass(ShopSettings);
