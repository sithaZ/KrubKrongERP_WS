import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Role } from '../common/enums/role.enum';
import { normalizeRole } from '../common/utils/role.utils';
import { AdjustStockDto } from './dto/adjust-stock.dto';
import { CreateProductDto } from './dto/create-product.dto';
import {
  InventoryMovement,
  InventoryMovementType,
} from './inventory-movement.entity';
import { Product } from './product.entity';
import { UpdateProductDto } from './dto/update-product.dto';

type RequestUser = {
  userId: string;
  role?: string;
  companyId?: string | null;
};

@Injectable()
export class ProductsService {
  constructor(
    @InjectModel(Product.name)
    private readonly productModel: Model<Product>,
    @InjectModel(InventoryMovement.name)
    private readonly movementModel: Model<InventoryMovement>,
  ) {}

  private isAdmin(user: RequestUser) {
    return user.role?.toUpperCase() === Role.ADMIN;
  }

  private isManagerLike(user: RequestUser) {
    const role = normalizeRole(user.role);
    return role === Role.MANAGER || role === Role.OWNER || this.isAdmin(user);
  }

  private getScopedCompanyId(user: RequestUser, overrideCompanyId?: string) {
    if (this.isAdmin(user)) {
      return overrideCompanyId ? new Types.ObjectId(overrideCompanyId) : undefined;
    }

    if (!user.companyId) {
      throw new ForbiddenException('This account is missing company access');
    }

    return new Types.ObjectId(user.companyId);
  }

  private buildAccessFilter(user: RequestUser) {
    if (this.isAdmin(user)) {
      return {};
    }

    if (!user.companyId) {
      throw new ForbiddenException('This account is missing company access');
    }

    return { companyId: new Types.ObjectId(user.companyId) };
  }

  private mapProduct(product: Product) {
    return {
      id: product._id.toString(),
      name: product.name,
      title: product.name,
      description: product.description || '',
      sku: product.sku,
      barcode: product.barcode || '',
      price: product.price,
      costPrice: product.costPrice ?? null,
      stockQuantity: product.stockQuantity,
      imageUrl: product.imageUrl || '',
      categoryId: product.categoryId,
      categoryName: product.categoryName || '',
      reorderLevel: product.reorderLevel,
      isActive: product.isActive,
      companyId: product.companyId?.toString() || null,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    };
  }

  private async ensureUniqueSku(baseSku: string) {
    let attempt = 0;
    let candidate = baseSku;

    while (await this.productModel.exists({ sku: candidate })) {
      attempt += 1;
      candidate = `${baseSku}-${attempt}`;
    }

    return candidate;
  }

  private async resolveSku(rawSku: string | undefined) {
    const normalizedSku = rawSku?.trim();
    if (normalizedSku) {
      const existingSku = await this.productModel.findOne({ sku: normalizedSku });
      if (existingSku) {
        throw new BadRequestException('SKU already exists');
      }
      return normalizedSku;
    }

    const generatedBaseSku = `PRD-${Date.now().toString().slice(-6)}`;
    return this.ensureUniqueSku(generatedBaseSku);
  }

  async findAll(
    currentUser: RequestUser,
    options?: {
      activeOnly?: boolean;
      inStockOnly?: boolean;
      search?: string;
      lowStockOnly?: boolean;
    },
  ) {
    const query: any = {
      ...this.buildAccessFilter(currentUser),
    };

    if (options?.activeOnly) {
      query.isActive = true;
    }

    if (options?.inStockOnly) {
      query.stockQuantity = { $gt: 0 };
    }

    if (options?.lowStockOnly) {
      query.$expr = { $lte: ['$stockQuantity', '$reorderLevel'] };
    }

    if (options?.search?.trim()) {
      const regex = new RegExp(options.search.trim(), 'i');
      query.$or = [
        { name: regex },
        { sku: regex },
        { barcode: regex },
        { categoryName: regex },
      ];
    }

    const products = await this.productModel
      .find(query)
      .sort({ createdAt: -1 })
      .exec();

    return products.map((product) => this.mapProduct(product));
  }

  async findOne(id: string, currentUser: RequestUser) {
    const product = await this.productModel.findOne({
      _id: id,
      ...this.buildAccessFilter(currentUser),
    });

    if (!product) {
      throw new NotFoundException('Product not found');
    }

    return this.mapProduct(product);
  }

  async create(dto: CreateProductDto, currentUser: RequestUser) {
    if (!this.isManagerLike(currentUser)) {
      throw new ForbiddenException('Only managers can manage inventory');
    }

    const normalizedSku = await this.resolveSku(dto.sku);

    const companyId = this.getScopedCompanyId(currentUser, dto.companyId);
    const createdBy = Types.ObjectId.isValid(currentUser.userId)
      ? new Types.ObjectId(currentUser.userId)
      : undefined;

    const product = await this.productModel.create({
      name: dto.name.trim(),
      description: dto.description?.trim() || '',
      sku: normalizedSku,
      barcode: dto.barcode?.trim() || '',
      price: dto.price,
      costPrice: dto.costPrice,
      stockQuantity: dto.stockQuantity,
      imageUrl: dto.imageUrl?.trim() || '',
      categoryId: dto.categoryId?.trim() || 'general',
      categoryName: dto.categoryName?.trim() || 'General',
      reorderLevel: dto.reorderLevel ?? 10,
      isActive: dto.isActive ?? true,
      companyId,
      createdBy,
      updatedBy: createdBy,
    });

    if (dto.stockQuantity > 0) {
      await this.movementModel.create({
        productId: product._id,
        companyId: product.companyId,
        type: InventoryMovementType.INITIAL_STOCK,
        quantityChange: dto.stockQuantity,
        stockBefore: 0,
        stockAfter: dto.stockQuantity,
        note: 'Initial inventory setup',
        createdBy,
      });
    }

    return this.mapProduct(product);
  }

  async update(id: string, dto: UpdateProductDto, currentUser: RequestUser) {
    if (!this.isManagerLike(currentUser)) {
      throw new ForbiddenException('Only managers can manage inventory');
    }

    const product = await this.productModel.findOne({
      _id: id,
      ...this.buildAccessFilter(currentUser),
    });

    if (!product) {
      throw new NotFoundException('Product not found');
    }

    if (dto.sku && dto.sku.trim() !== product.sku) {
      const duplicate = await this.productModel.findOne({ sku: dto.sku.trim() });
      if (duplicate && duplicate._id.toString() !== product._id.toString()) {
        throw new BadRequestException('SKU already exists');
      }
      product.sku = dto.sku.trim();
    }

    if (dto.name !== undefined) product.name = dto.name.trim();
    if (dto.description !== undefined) product.description = dto.description.trim();
    if (dto.barcode !== undefined) product.barcode = dto.barcode.trim();
    if (dto.price !== undefined) product.price = dto.price;
    if (dto.costPrice !== undefined) product.costPrice = dto.costPrice;
    const stockBefore = product.stockQuantity;
    if (dto.stockQuantity !== undefined) {
      if (dto.stockQuantity < 0) {
        throw new BadRequestException('Stock cannot go below zero');
      }
      product.stockQuantity = dto.stockQuantity;
    }
    if (dto.imageUrl !== undefined) product.imageUrl = dto.imageUrl.trim();
    if (dto.categoryId !== undefined) product.categoryId = dto.categoryId.trim();
    if (dto.categoryName !== undefined) {
      product.categoryName = dto.categoryName.trim();
    }
    if (dto.reorderLevel !== undefined) product.reorderLevel = dto.reorderLevel;
    if (dto.isActive !== undefined) product.isActive = dto.isActive;
    if (Types.ObjectId.isValid(currentUser.userId)) {
      product.updatedBy = new Types.ObjectId(currentUser.userId);
    }

    await product.save();

    if (dto.stockQuantity !== undefined && dto.stockQuantity != stockBefore) {
      await this.movementModel.create({
        productId: product._id,
        companyId: product.companyId,
        type:
          dto.stockQuantity > stockBefore
            ? InventoryMovementType.RESTOCK
            : InventoryMovementType.ADJUSTMENT,
        quantityChange: dto.stockQuantity - stockBefore,
        stockBefore,
        stockAfter: dto.stockQuantity,
        note: 'Stock updated from product edit',
        createdBy: Types.ObjectId.isValid(currentUser.userId)
          ? new Types.ObjectId(currentUser.userId)
          : undefined,
      });
    }

    return this.mapProduct(product);
  }

  async adjustStock(id: string, dto: AdjustStockDto, currentUser: RequestUser) {
    if (!this.isManagerLike(currentUser)) {
      throw new ForbiddenException('Only managers can manage inventory');
    }

    const product = await this.productModel.findOne({
      _id: id,
      ...this.buildAccessFilter(currentUser),
    });

    if (!product) {
      throw new NotFoundException('Product not found');
    }

    const stockBefore = product.stockQuantity;
    const stockAfter = stockBefore + dto.quantityChange;

    if (stockAfter < 0) {
      throw new BadRequestException('Stock cannot go below zero');
    }

    product.stockQuantity = stockAfter;
    if (Types.ObjectId.isValid(currentUser.userId)) {
      product.updatedBy = new Types.ObjectId(currentUser.userId);
    }
    await product.save();

    await this.movementModel.create({
      productId: product._id,
      companyId: product.companyId,
      type: dto.type,
      quantityChange: dto.quantityChange,
      stockBefore,
      stockAfter,
      note: dto.note || '',
      createdBy: Types.ObjectId.isValid(currentUser.userId)
        ? new Types.ObjectId(currentUser.userId)
        : undefined,
    });

    return this.mapProduct(product);
  }

  async getLowStock(currentUser: RequestUser) {
    return this.findAll(currentUser, {
      activeOnly: true,
      lowStockOnly: true,
    });
  }
}
