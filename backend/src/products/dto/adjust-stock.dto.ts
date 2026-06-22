import { IsEnum, IsNumber, IsOptional, IsString } from 'class-validator';
import { InventoryMovementType } from '../inventory-movement.entity';

export class AdjustStockDto {
  @IsEnum(InventoryMovementType)
  type: InventoryMovementType;

  @IsNumber()
  quantityChange: number;

  @IsOptional()
  @IsString()
  note?: string;
}
