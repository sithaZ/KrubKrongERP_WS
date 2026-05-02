import {
  IsString,
  IsNumber,
  IsOptional,
  IsBoolean,
  IsMongoId,
  Min,
} from 'class-validator';

export class CreateProductDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsString()
  sku: string;

  @IsNumber()
  @Min(0)
  price: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  costPrice?: number;

  @IsNumber()
  @Min(0)
  stockQuantity: number;

  @IsOptional()
  @IsString()
  imageUrl?: string;

  @IsMongoId()
  categoryId: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
