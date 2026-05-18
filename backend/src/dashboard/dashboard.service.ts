import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Order } from '../orders/order.entity';
import { Product } from '../products/product.entity';
import { Employee } from '../employees/employee.entity';
import { User } from '../users/user.entity';
import { Company } from '../companies/company.entity';
import { Role } from '../common/enums/role.enum';

@Injectable()
export class DashboardService {
  constructor(
    @InjectModel(Order.name) private orderModel: Model<Order>,
    @InjectModel(Product.name) private productModel: Model<Product>,
    @InjectModel(Employee.name) private employeeModel: Model<Employee>,
    @InjectModel(User.name) private userModel: Model<User>,
    @InjectModel(Company.name) private companyModel: Model<Company>,
  ) {}

  async getStats() {
    const totalShops = await this.companyModel.countDocuments();
    const activeShops = await this.companyModel.countDocuments({
      status: 'active',
      subscriptionStatus: { $in: ['Trial', 'Active'] },
    });
    const totalManagers = await this.userModel.countDocuments({
      role: { $in: [Role.MANAGER, Role.OWNER, 'manager', 'owner'] },
    });
    const activeSubscriptions = await this.companyModel.countDocuments({
      subscriptionStatus: 'Active',
      status: 'active',
      isActive: true,
    });
    const atRiskShops = await this.companyModel.countDocuments({
      subscriptionStatus: { $in: ['Expired', 'Suspended'] },
    });
    const renewalAlerts = await this.companyModel.countDocuments({
      subscriptionStatus: { $in: ['Trial', 'Active'] },
      nextRenewalDate: {
        $gte: new Date(),
        $lte: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
      },
    });

    const totalSubscriptionRevenue = await this.companyModel.aggregate([
      {
        $match: {
          subscriptionStatus: { $in: ['Active', 'Trial'] },
          status: 'active',
        },
      },
      { $group: { _id: null, total: { $sum: '$subscriptionPrice' } } },
    ]);

    const estimatedYearlyRevenue = await this.companyModel.aggregate([
      {
        $match: {
          subscriptionStatus: { $in: ['Trial', 'Active'] },
          status: 'active',
        },
      },
      { $group: { _id: null, total: { $sum: '$subscriptionPrice' } } },
    ]);

    return {
      totalShops,
      activeShops,
      totalManagers,
      activeSubscriptions,
      expiredShops: atRiskShops,
      suspendedOrExpiredShops: atRiskShops,
      renewalAlerts,
      totalSubscriptionRevenue:
        totalSubscriptionRevenue[0]?.total || activeSubscriptions * 50,
      estimatedYearlyRevenue:
        estimatedYearlyRevenue[0]?.total || activeShops * 50,
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
