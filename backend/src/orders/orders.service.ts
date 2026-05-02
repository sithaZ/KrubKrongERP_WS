import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Order, OrderStatus } from './order.entity';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';

@Injectable()
export class OrdersService {
  constructor(@InjectModel(Order.name) private orderModel: Model<Order>) {}

  async createOrder(
    createOrderDto: CreateOrderDto,
    cashierId: string,
  ): Promise<Order> {
    const newOrder = new this.orderModel({
      ...createOrderDto,
      cashierId,
      status: OrderStatus.PENDING,
    });

    return newOrder.save();
  }

  async getOrders(
    dateFrom?: string,
    dateTo?: string,
    status?: OrderStatus,
    cashierId?: string,
  ): Promise<Order[]> {
    const query: any = {};

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

    if (cashierId) {
      query.cashierId = cashierId;
    }

    return this.orderModel
      .find(query)
      .populate('cashierId', 'name email')
      .sort({ createdAt: -1 })
      .exec();
  }

  async getOrderById(id: string): Promise<Order> {
    const order = await this.orderModel
      .findById(id)
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
  ): Promise<Order> {
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

  async deleteOrder(id: string): Promise<Order> {
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
}
