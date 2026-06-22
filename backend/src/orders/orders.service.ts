import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Role } from '../common/enums/role.enum';
import { normalizeRole } from '../common/utils/role.utils';
import {
  InventoryMovement,
  InventoryMovementType,
} from '../products/inventory-movement.entity';
import { Product } from '../products/product.entity';
import { Order, OrderStatus } from './order.entity';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';

type RequestUser = {
  userId: string;
  role?: string;
  companyId?: string | null;
};

@Injectable()
export class OrdersService {
  constructor(
    @InjectModel(Order.name) private orderModel: Model<Order>,
    @InjectModel(Product.name) private productModel: Model<Product>,
    @InjectModel(InventoryMovement.name)
    private movementModel: Model<InventoryMovement>,
  ) {}

  private isAdmin(user: RequestUser) {
    return user.role?.toUpperCase() === Role.ADMIN;
  }

  private buildAccessFilter(currentUser: RequestUser, cashierId?: string) {
    const role = normalizeRole(currentUser.role);
    const query: any = {};

    if (this.isAdmin(currentUser)) {
      if (cashierId) {
        query.cashierId = cashierId;
      }
      return query;
    }

    if (currentUser.companyId) {
      query.companyId = new Types.ObjectId(currentUser.companyId);
    }

    if (role === Role.EMPLOYEE || currentUser.role?.toUpperCase() === 'STAFF') {
      query.cashierId = new Types.ObjectId(currentUser.userId);
      return query;
    }

    if (cashierId) {
      query.cashierId = cashierId;
    }

    return query;
  }

  private ensureManagerVisibility(currentUser: RequestUser) {
    const role = normalizeRole(currentUser.role);
    if (
      role !== Role.MANAGER &&
      role !== Role.OWNER &&
      !this.isAdmin(currentUser)
    ) {
      throw new ForbiddenException('Only managers can access receipt performance');
    }
  }

  private generateReceiptNumber() {
    const timestamp = Date.now();
    const suffix = Math.floor(Math.random() * 1000)
      .toString()
      .padStart(3, '0');
    return `R-${timestamp}-${suffix}`;
  }

  async createOrder(
    createOrderDto: CreateOrderDto,
    currentUser: RequestUser,
  ): Promise<Order> {
    if (!createOrderDto.items.length) {
      throw new BadRequestException('At least one product is required');
    }

    const productIds = createOrderDto.items.map((item) => item.productId);
    const products = await this.productModel.find({
      _id: { $in: productIds },
    });

    const productsById = new Map(
      products.map((product) => [product._id.toString(), product]),
    );

    const resolvedItems = createOrderDto.items.map((item) => {
      const product = productsById.get(item.productId);
      if (!product) {
        throw new NotFoundException(`Product ${item.productId} not found`);
      }

      if (!product.isActive) {
        throw new BadRequestException(`${product.name} is inactive`);
      }

      if (
        !this.isAdmin(currentUser) &&
        currentUser.companyId &&
        product.companyId?.toString() !== currentUser.companyId
      ) {
        throw new ForbiddenException(
          `You cannot sell products from another company`,
        );
      }

      if (product.stockQuantity < item.quantity) {
        throw new BadRequestException(
          `Not enough stock for ${product.name}. Available: ${product.stockQuantity}`,
        );
      }

      return {
        product,
        quantity: item.quantity,
        total: Number((product.price * item.quantity).toFixed(2)),
      };
    });

    const subtotal = Number(
      resolvedItems.reduce((sum, item) => sum + item.total, 0).toFixed(2),
    );
    const discount = Number((createOrderDto.discount ?? 0).toFixed(2));
    const tax = Number((createOrderDto.tax ?? 0).toFixed(2));
    const total = Number((subtotal - discount + tax).toFixed(2));

    if (total < 0) {
      throw new BadRequestException('Order total cannot be negative');
    }

    const companyId =
      resolvedItems[0]?.product.companyId ||
      (currentUser.companyId ? new Types.ObjectId(currentUser.companyId) : undefined);
    const cashierObjectId = new Types.ObjectId(currentUser.userId);
    const receiptNumber = this.generateReceiptNumber();

    const newOrder = new this.orderModel({
      items: resolvedItems.map(({ product, quantity, total: lineTotal }) => ({
        productId: product._id,
        productName: product.name,
        unitPrice: product.price,
        quantity,
        total: lineTotal,
        imageUrl: product.imageUrl || '',
      })),
      subtotal,
      discount,
      tax,
      total,
      customerId: createOrderDto.customerId,
      customerName: createOrderDto.customerName,
      companyId,
      cashierId: cashierObjectId,
      receiptNumber,
      paymentMethod: createOrderDto.paymentMethod || 'cash',
      notes: createOrderDto.notes,
      status: OrderStatus.COMPLETED,
    });

    const order = await newOrder.save();

    for (const item of resolvedItems) {
      const stockBefore = item.product.stockQuantity;
      item.product.stockQuantity = stockBefore - item.quantity;
      await item.product.save();

      await this.movementModel.create({
        productId: item.product._id,
        companyId: item.product.companyId,
        type: InventoryMovementType.SALE_OUT,
        quantityChange: -item.quantity,
        stockBefore,
        stockAfter: item.product.stockQuantity,
        referenceId: order._id.toString(),
        note: `Sold via POS receipt ${receiptNumber}`,
        createdBy: cashierObjectId,
      });
    }

    return this.getOrderById(order._id.toString(), currentUser);
  }

  async getOrders(
    currentUser: RequestUser,
    dateFrom?: string,
    dateTo?: string,
    status?: OrderStatus,
    cashierId?: string,
  ): Promise<Order[]> {
    const query: any = this.buildAccessFilter(currentUser, cashierId);

    if (dateFrom || dateTo) {
      query.createdAt = {};
      if (dateFrom) {
        query.createdAt.$gte = new Date(dateFrom);
      }
      if (dateTo) {
        query.createdAt.$lte = new Date(dateTo);
      }
    }

    if (status) {
      query.status = status;
    }

    return this.orderModel
      .find(query)
      .populate('cashierId', 'name email')
      .sort({ createdAt: -1 })
      .exec();
  }

  async getOrderById(id: string, currentUser: RequestUser): Promise<Order> {
    const order = await this.orderModel
      .findOne({
        _id: id,
        ...this.buildAccessFilter(currentUser),
      })
      .populate('cashierId', 'name email')
      .exec();

    if (!order) {
      throw new NotFoundException(`Order with ID ${id} not found`);
    }

    return order;
  }

  async updateOrderStatus(
    id: string,
    updateOrderStatusDto: UpdateOrderStatusDto,
    currentUser: RequestUser,
  ): Promise<Order> {
    this.ensureManagerVisibility(currentUser);

    const order = await this.orderModel
      .findByIdAndUpdate(
        id,
        { status: updateOrderStatusDto.status },
        { returnDocument: 'after' },
      )
      .populate('cashierId', 'name email')
      .exec();

    if (!order) {
      throw new NotFoundException(`Order with ID ${id} not found`);
    }

    return order;
  }

  async deleteOrder(id: string, currentUser: RequestUser): Promise<Order> {
    this.ensureManagerVisibility(currentUser);

    const order = await this.orderModel
      .findByIdAndUpdate(
        id,
        { status: OrderStatus.CANCELLED },
        { returnDocument: 'after' },
      )
      .populate('cashierId', 'name email')
      .exec();

    if (!order) {
      throw new NotFoundException(`Order with ID ${id} not found`);
    }

    return order;
  }

  async getPerformanceSummary(
    currentUser: RequestUser,
    dateFrom?: string,
    dateTo?: string,
  ) {
    this.ensureManagerVisibility(currentUser);
    const query: any = this.buildAccessFilter(currentUser);

    if (dateFrom || dateTo) {
      query.createdAt = {};
      if (dateFrom) {
        query.createdAt.$gte = new Date(dateFrom);
      }
      if (dateTo) {
        query.createdAt.$lte = new Date(dateTo);
      }
    }

    const orders = await this.orderModel
      .find(query)
      .populate('cashierId', 'name email')
      .sort({ createdAt: -1 })
      .exec();

    const totalReceipts = orders.length;
    const completedReceipts = orders.filter(
      (order) => order.status === OrderStatus.COMPLETED,
    ).length;
    const refundedReceipts = orders.filter(
      (order) => order.status === OrderStatus.REFUNDED,
    ).length;
    const cancelledReceipts = orders.filter(
      (order) => order.status === OrderStatus.CANCELLED,
    ).length;
    const totalRevenue = Number(
      orders
        .filter((order) => order.status === OrderStatus.COMPLETED)
        .reduce((sum, order) => sum + order.total, 0)
        .toFixed(2),
    );

    const cashierMap = new Map<
      string,
      { cashierId: string; cashierName: string; receiptCount: number; revenue: number }
    >();

    for (const order of orders) {
      const cashier = order.cashierId as any;
      const cashierId = cashier?._id?.toString?.() || order.cashierId.toString();
      const cashierName = cashier?.name || 'Unknown cashier';
      const current = cashierMap.get(cashierId) || {
        cashierId,
        cashierName,
        receiptCount: 0,
        revenue: 0,
      };

      current.receiptCount += 1;
      if (order.status === OrderStatus.COMPLETED) {
        current.revenue += order.total;
      }
      cashierMap.set(cashierId, current);
    }

    return {
      totalReceipts,
      completedReceipts,
      refundedReceipts,
      cancelledReceipts,
      totalRevenue,
      averageReceiptValue:
        completedReceipts > 0
          ? Number((totalRevenue / completedReceipts).toFixed(2))
          : 0,
      staffPerformance: Array.from(cashierMap.values())
        .map((entry) => ({
          ...entry,
          revenue: Number(entry.revenue.toFixed(2)),
        }))
        .sort((a, b) => b.revenue - a.revenue),
      recentReceipts: orders.slice(0, 10),
    };
  }
}
