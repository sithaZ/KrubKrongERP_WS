import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthModule } from '../auth/auth.module';
import {
  InventoryMovement,
  InventoryMovementSchema,
} from './inventory-movement.entity';
import { Product, ProductSchema } from './product.entity';
import { ProductsController } from './products.controller';
import { ProductsService } from './products.service';

@Module({
  imports: [
    AuthModule,
    MongooseModule.forFeature([
      { name: Product.name, schema: ProductSchema },
      { name: InventoryMovement.name, schema: InventoryMovementSchema },
    ]),
  ],
  controllers: [ProductsController],
  providers: [ProductsService],
  exports: [ProductsService, MongooseModule],
})
export class ProductsModule {}
