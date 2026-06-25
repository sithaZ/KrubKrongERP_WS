import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { ForbiddenException } from '@nestjs/common';
import { Model, Types } from 'mongoose';
import { Order } from '../orders/order.entity';
import { Employee } from '../employees/employee.entity';
import { User } from '../users/user.entity';
import { Company } from '../companies/company.entity';
import { Role } from '../common/enums/role.enum';
import { Product } from '../products/product.entity';
import { Attendance, AttendanceStatus } from '../attendance/attendance.entity';
import { normalizeRole } from '../common/utils/role.utils';

type RequestUser = {
  userId: string;
  role?: string;
  companyId?: string | null;
};

@Injectable()
export class DashboardService {
  constructor(
    @InjectModel(Order.name) private orderModel: Model<Order>,
    @InjectModel(Employee.name) private employeeModel: Model<Employee>,
    @InjectModel(User.name) private userModel: Model<User>,
    @InjectModel(Company.name) private companyModel: Model<Company>,
    @InjectModel(Product.name) private productModel: Model<Product>,
    @InjectModel(Attendance.name) private attendanceModel: Model<Attendance>,
  ) {}

  private isAdmin(user: RequestUser) {
    return user.role?.toUpperCase() === Role.ADMIN;
  }

  private ensureShopAccess(user: RequestUser) {
    const normalizedRole = normalizeRole(user.role);
    const isOwner = user.role?.toUpperCase() === Role.OWNER;

    if (normalizedRole !== Role.MANAGER && !isOwner && !this.isAdmin(user)) {
      throw new ForbiddenException(
        'Only shop managers and owners can access the shop dashboard',
      );
    }

    if (!user.companyId && !this.isAdmin(user)) {
      throw new ForbiddenException(
        'This account is missing company access for the dashboard',
      );
    }
  }

  private buildCompanyFilter(user: RequestUser) {
    if (user.companyId) {
      return {
        companyId: new Types.ObjectId(user.companyId),
      };
    }

    return {};
  }

  private buildDateRangeFilter(start: Date, end: Date) {
    return {
      createdAt: {
        $gte: start,
        $lt: end,
      },
    };
  }

  private async getRevenueSnapshot(
    companyFilter: Record<string, unknown>,
    start: Date,
    end: Date,
  ) {
    const [summary] = await this.orderModel.aggregate([
      {
        $match: {
          ...companyFilter,
          status: 'completed',
          ...this.buildDateRangeFilter(start, end),
        },
      },
      {
        $group: {
          _id: null,
          totalRevenue: { $sum: '$total' },
          orderCount: { $sum: 1 },
          averageOrderValue: { $avg: '$total' },
        },
      },
    ]);

    return {
      totalRevenue: Number((summary?.totalRevenue ?? 0).toFixed(2)),
      orderCount: summary?.orderCount ?? 0,
      averageOrderValue: Number((summary?.averageOrderValue ?? 0).toFixed(2)),
    };
  }

  async getShopSummary(currentUser: RequestUser) {
    this.ensureShopAccess(currentUser);

    const companyFilter = this.buildCompanyFilter(currentUser);
    const now = new Date();
    const todayStart = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
    );
    const tomorrowStart = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate() + 1,
    );
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const nextMonthStart = new Date(now.getFullYear(), now.getMonth() + 1, 1);
    const yearStart = new Date(now.getFullYear(), 0, 1);
    const nextYearStart = new Date(now.getFullYear() + 1, 0, 1);
    const todayString = now.toISOString().split('T')[0];

    const [
      dailyRevenue,
      monthlyRevenue,
      yearlyRevenue,
      totalProducts,
      totalStaff,
      attendanceRecords,
      recentOrders,
      recentAttendance,
      refundedToday,
    ] = await Promise.all([
      this.getRevenueSnapshot(companyFilter, todayStart, tomorrowStart),
      this.getRevenueSnapshot(companyFilter, monthStart, nextMonthStart),
      this.getRevenueSnapshot(companyFilter, yearStart, nextYearStart),
      this.productModel.countDocuments(companyFilter),
      this.employeeModel.countDocuments({ ...companyFilter, isActive: true }),
      this.attendanceModel
        .find({
          ...companyFilter,
          attendanceDate: todayString,
        })
        .exec(),
      this.orderModel
        .find(companyFilter)
        .populate('cashierId', 'name')
        .sort({ createdAt: -1 })
        .limit(6)
        .lean()
        .exec(),
      this.attendanceModel
        .find({
          ...companyFilter,
          $or: [
            { checkInTime: { $ne: null } },
            { checkOutTime: { $ne: null } },
          ],
        })
        .populate('employeeId', 'fullName')
        .sort({ updatedAt: -1, createdAt: -1 })
        .limit(6)
        .lean()
        .exec(),
      this.orderModel.aggregate([
        {
          $match: {
            ...companyFilter,
            status: 'refunded',
            ...this.buildDateRangeFilter(todayStart, tomorrowStart),
          },
        },
        {
          $group: {
            _id: null,
            totalRefunds: { $sum: '$total' },
          },
        },
      ]),
    ]);

    let presentCount = 0;
    let lateCount = 0;

    for (const record of attendanceRecords) {
      if (
        record.attendanceStatus === AttendanceStatus.PRESENT ||
        record.attendanceStatus === AttendanceStatus.LATE ||
        record.attendanceStatus === AttendanceStatus.HALF_DAY
      ) {
        presentCount += 1;
      }

      if (record.attendanceStatus === AttendanceStatus.LATE) {
        lateCount += 1;
      }
    }

    const absentCount = Math.max(0, totalStaff - presentCount);

    const orderActivities = recentOrders.map((order: any) => {
      const cashierName = order.cashierId?.name || 'Unknown staff';
      const itemCount = Array.isArray(order.items)
        ? order.items.reduce(
            (sum: number, item: { quantity?: number }) =>
              sum + (item.quantity ?? 0),
            0,
          )
        : 0;

      return {
        id: `order-${order._id}`,
        type: 'order',
        title: `Order ${order.receiptNumber}`,
        description: `${cashierName} processed ${itemCount} item(s) for $${Number(order.total ?? 0).toFixed(2)}`,
        actorName: cashierName,
        amount: Number((order.total ?? 0).toFixed(2)),
        status: order.status,
        occurredAt: order.createdAt,
      };
    });

    const attendanceActivities = recentAttendance.map((record: any) => {
      const staffName = record.employeeId?.fullName || 'Unknown staff';
      const checkedOutAt = record.checkOutTime ?? record.checkOut;
      const checkedInAt = record.checkInTime ?? record.checkIn;
      const isCheckout = checkedOutAt != null;
      const isLate = record.attendanceStatus === AttendanceStatus.LATE;

      return {
        id: `attendance-${record._id}`,
        type: isCheckout ? 'check_out' : 'check_in',
        title: isCheckout
          ? `${staffName} checked out`
          : isLate
            ? `${staffName} checked in late`
            : `${staffName} checked in`,
        description: isCheckout
          ? `${staffName} completed the shift`
          : isLate
            ? `${staffName} arrived after the grace period`
            : `${staffName} started the shift`,
        actorName: staffName,
        amount: null,
        status: record.attendanceStatus,
        occurredAt:
          checkedOutAt ?? checkedInAt ?? record.updatedAt ?? record.createdAt,
      };
    });

    const recentActivities = [...orderActivities, ...attendanceActivities]
      .sort((a, b) => {
        const left = new Date(a.occurredAt ?? 0).getTime();
        const right = new Date(b.occurredAt ?? 0).getTime();
        return right - left;
      })
      .slice(0, 8);

    return {
      revenue: {
        daily: dailyRevenue.totalRevenue,
        monthly: monthlyRevenue.totalRevenue,
        yearly: yearlyRevenue.totalRevenue,
      },
      today: {
        grossSales: dailyRevenue.totalRevenue,
        orderCount: dailyRevenue.orderCount,
        averageOrderValue: dailyRevenue.averageOrderValue,
        refunds: Number((refundedToday[0]?.totalRefunds ?? 0).toFixed(2)),
      },
      quickStats: {
        totalProducts,
        totalStaff,
        presentStaff: presentCount,
      },
      attendance: {
        present: presentCount,
        late: lateCount,
        absent: absentCount,
      },
      recentActivities,
    };
  }

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
