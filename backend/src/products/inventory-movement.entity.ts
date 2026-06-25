import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export enum InventoryMovementType {
  INITIAL_STOCK = 'INITIAL_STOCK',
  RESTOCK = 'RESTOCK',
  ADJUSTMENT = 'ADJUSTMENT',
  SALE_OUT = 'SALE_OUT',
}

@Schema({ timestamps: true })
export class InventoryMovement extends Document {
  @Prop({ type: Types.ObjectId, ref: 'Product', required: true, index: true })
  productId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Company', index: true })
  companyId?: Types.ObjectId;

  @Prop({
    required: true,
    enum: Object.values(InventoryMovementType),
  })
  type: InventoryMovementType;

  @Prop({ required: true })
  quantityChange: number;

  @Prop({ required: true, min: 0 })
  stockBefore: number;

  @Prop({ required: true, min: 0 })
  stockAfter: number;

  @Prop()
  referenceId?: string;

  @Prop({ default: '' })
  note?: string;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  createdBy?: Types.ObjectId;
}

export const InventoryMovementSchema =
  SchemaFactory.createForClass(InventoryMovement);
InventoryMovementSchema.index({ companyId: 1, createdAt: -1 });
