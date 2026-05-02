import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Order } from '../orders/order.entity';
import { Product } from '../products/product.entity';
import { Employee } from '../employees/employee.entity';
import { User } from '../users/user.entity';

@Injectable()
export class DashboardService {
  constructor(
    @InjectModel(Order.name) private orderModel: Model<Order>,
    @InjectModel(Product.name) private productModel: Model<Product>,
    @InjectModel(Employee.name) private employeeModel: Model<Employee>,
    @InjectModel(User.name) private userModel: Model<User>,
  ) {}

  async getStats() {
    const totalOrders = await this.orderModel.countDocuments();
    const completedOrders = await this.orderModel.countDocuments({
      status: 'completed',
    });
    const totalProducts = await this.productModel.countDocuments({
      isActive: true,
    });
    const lowStockProducts = await this.productModel.countDocuments({
      stockQuantity: { $lte: 10 },
    });
    const totalStaff = await this.employeeModel.countDocuments({
      isActive: true,
    });
    const totalUsers = await this.userModel.countDocuments({ isActive: true });

    const totalRevenue = await this.orderModel.aggregate([
      { $match: { status: 'completed' } },
      { $group: { _id: null, total: { $sum: '$total' } } },
    ]);

    return {
      totalOrders,
      completedOrders,
      totalProducts,
      lowStockProducts,
      totalStaff,
      totalUsers,
      totalRevenue: totalRevenue[0]?.total || 0,
    };
  }

  async getSalesData(dateFrom?: string, dateTo?: string) {
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

    const salesData = await this.orderModel.aggregate([
      { $match: { ...query, status: 'completed' } },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
          totalSales: { $sum: '$total' },
          orderCount: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    return salesData;
  }

  async getTopProducts(limit: number = 10) {
    const topProducts = await this.orderModel.aggregate([
      { $match: { status: 'completed' } },
      { $unwind: '$items' },
      {
        $group: {
          _id: '$items.productId',
          productName: { $first: '$items.productName' },
          totalQuantity: { $sum: '$items.quantity' },
          totalRevenue: { $sum: '$items.total' },
        },
      },
      { $sort: { totalQuantity: -1 } },
      { $limit: limit },
    ]);

    return topProducts;
  }

  async getRevenueData(dateFrom?: string, dateTo?: string) {
    const query: any = { status: 'completed' };

    if (dateFrom || dateTo) {
      query.createdAt = {};
      if (dateFrom) {
        query.createdAt.$gte = new Date(dateFrom);
      }
      if (dateTo) {
        query.createdAt.$lte = new Date(dateTo);
      }
    }

    const revenueData = await this.orderModel.aggregate([
      { $match: query },
      {
        $group: {
          _id: null,
          totalRevenue: { $sum: '$total' },
          totalTax: { $sum: '$tax' },
          averageOrderValue: { $avg: '$total' },
          orderCount: { $sum: 1 },
        },
      },
    ]);

    return (
      revenueData[0] || {
        totalRevenue: 0,
        totalTax: 0,
        averageOrderValue: 0,
        orderCount: 0,
      }
    );
  }
}
