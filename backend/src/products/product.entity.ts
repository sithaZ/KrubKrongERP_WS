import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

@Schema({ timestamps: true })
export class Product extends Document {
  @Prop({ required: true, trim: true })
  name: string;

  @Prop({ default: '', trim: true })
  description?: string;

  @Prop({ required: true, trim: true, unique: true })
  sku: string;

  @Prop({ default: '', trim: true })
  barcode?: string;

  @Prop({ required: true, min: 0 })
  price: number;

  @Prop({ min: 0 })
  costPrice?: number;

  @Prop({ required: true, min: 0, default: 0 })
  stockQuantity: number;

  @Prop({ default: '' })
  imageUrl?: string;

  @Prop({ default: 'general', trim: true })
  categoryId: string;

  @Prop({ default: 'General', trim: true })
  categoryName?: string;

  @Prop({ required: true, min: 0, default: 10 })
  reorderLevel: number;

  @Prop({ default: true })
  isActive: boolean;

  @Prop({ type: Types.ObjectId, ref: 'Company', index: true })
  companyId?: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  createdBy?: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  updatedBy?: Types.ObjectId;

  createdAt?: Date;

  updatedAt?: Date;
}

export const ProductSchema = SchemaFactory.createForClass(Product);
ProductSchema.index({ companyId: 1, name: 1 });
