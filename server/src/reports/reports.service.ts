import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  SalesReportDto,
  TopProductsDto,
  RevenueDto,
  InventoryReportDto,
  CashierPerformanceDto,
} from './dto/report-query.dto';

@Injectable()
export class ReportsService {
  constructor(private prisma: PrismaService) {}

  async sales(query: SalesReportDto) {
    const { startDate, endDate } = this.resolveDateRange(
      query.period ?? 'daily',
      query.startDate,
      query.endDate,
    );

    const where: Prisma.OrderWhereInput = {
      createdAt: { gte: startDate, lte: endDate },
      status: { not: 'CANCELLED' },
    };
    if (query.cashierId) where.cashierId = query.cashierId;

    const [orders, agg, paymentBreakdown] = await Promise.all([
      this.prisma.order.groupBy({
        by: ['createdAt'],
        where,
        _count: true,
        _sum: { total: true, taxAmount: true, discountAmount: true },
      }),
      this.prisma.order.aggregate({
        where,
        _count: true,
        _sum: { total: true, subtotal: true, taxAmount: true, discountAmount: true },
        _avg: { total: true },
      }),
      this.prisma.order.groupBy({
        by: ['paymentMethod'],
        where,
        _count: true,
        _sum: { total: true },
      }),
    ]);

    return {
      summary: {
        totalOrders: agg._count,
        totalRevenue: agg._sum.total ?? 0,
        avgOrderValue: agg._avg.total ?? 0,
        totalTax: agg._sum.taxAmount ?? 0,
        totalDiscounts: agg._sum.discountAmount ?? 0,
      },
      paymentBreakdown: paymentBreakdown.map((p) => ({
        method: p.paymentMethod,
        count: p._count,
        total: p._sum.total ?? 0,
      })),
      period: { start: startDate, end: endDate },
    };
  }

  async topProducts(query: TopProductsDto) {
    const { startDate, endDate } = this.resolveDateRange(
      query.period ?? 'monthly',
      query.startDate,
      query.endDate,
    );
    const limit = query.limit ?? 10;

    const top = await this.prisma.$queryRaw<
      { product_id: number; product_name: string; total_qty: bigint; total_revenue: number; order_count: bigint }[]
    >`
      SELECT
        oi.product_id,
        oi.product_name,
        SUM(oi.quantity)::bigint AS total_qty,
        SUM(oi.subtotal)::numeric AS total_revenue,
        COUNT(DISTINCT oi.order_id)::bigint AS order_count
      FROM order_items oi
      JOIN orders o ON o.id = oi.order_id
      WHERE o.created_at >= ${startDate}
        AND o.created_at <= ${endDate}
        AND o.status != 'CANCELLED'
      GROUP BY oi.product_id, oi.product_name
      ORDER BY total_qty DESC
      LIMIT ${limit}
    `;

    return top.map((row) => ({
      productId: row.product_id,
      productName: row.product_name,
      totalQuantity: Number(row.total_qty),
      totalRevenue: Number(row.total_revenue),
      orderCount: Number(row.order_count),
    }));
  }

  async revenue(query: RevenueDto) {
    const groupBy = query.groupBy ?? 'daily';
    const endDate = query.endDate ? new Date(query.endDate) : new Date();
    const startDate = query.startDate
      ? new Date(query.startDate)
      : new Date(endDate.getTime() - 30 * 24 * 60 * 60 * 1000);

    const truncFn =
      groupBy === 'monthly'
        ? `date_trunc('month', created_at)`
        : groupBy === 'weekly'
          ? `date_trunc('week', created_at)`
          : `date_trunc('day', created_at)`;

    const rows = await this.prisma.$queryRawUnsafe<
      { period: Date; orders: bigint; revenue: number; avg_order: number }[]
    >(
      `SELECT
        ${truncFn} AS period,
        COUNT(*)::bigint AS orders,
        SUM(total)::numeric AS revenue,
        AVG(total)::numeric AS avg_order
      FROM orders
      WHERE created_at >= $1
        AND created_at <= $2
        AND status != 'CANCELLED'
      GROUP BY period
      ORDER BY period`,
      startDate,
      endDate,
    );

    const totals = await this.prisma.order.aggregate({
      where: {
        createdAt: { gte: startDate, lte: endDate },
        status: { not: 'CANCELLED' },
      },
      _count: true,
      _sum: { total: true, subtotal: true, taxAmount: true, discountAmount: true },
    });

    return {
      data: rows.map((r) => ({
        period: r.period,
        orders: Number(r.orders),
        revenue: Number(r.revenue),
        avgOrderValue: Number(r.avg_order),
      })),
      totals: {
        orders: totals._count,
        revenue: totals._sum.total ?? 0,
        subtotal: totals._sum.subtotal ?? 0,
        tax: totals._sum.taxAmount ?? 0,
        discounts: totals._sum.discountAmount ?? 0,
      },
    };
  }

  async inventory(query: InventoryReportDto) {
    const where: Prisma.ProductWhereInput = { isActive: true };
    if (query.categoryId) where.categoryId = query.categoryId;

    const products = await this.prisma.product.findMany({
      where,
      include: { category: { select: { name: true } } },
      orderBy: { stock: 'asc' },
    });

    let result = products.map((p) => ({
      id: p.id,
      name: p.name,
      sku: p.sku,
      category: p.category?.name ?? 'Uncategorized',
      stock: p.stock,
      lowStockThreshold: p.lowStockThreshold,
      price: p.price,
      cost: p.cost,
      stockValue: Number(p.price) * p.stock,
      costValue: Number(p.cost) * p.stock,
      potentialProfit: (Number(p.price) - Number(p.cost)) * p.stock,
      isLowStock: p.stock <= p.lowStockThreshold,
    }));

    if (query.lowStockOnly === 'true') {
      result = result.filter((p) => p.isLowStock);
    }

    const totalStockValue = result.reduce((sum, p) => sum + p.stockValue, 0);
    const totalCostValue = result.reduce((sum, p) => sum + p.costValue, 0);

    return {
      products: result,
      summary: {
        totalProducts: result.length,
        totalStockValue,
        totalCostValue,
        totalPotentialProfit: totalStockValue - totalCostValue,
        lowStockCount: result.filter((p) => p.isLowStock).length,
      },
    };
  }

  async cashierPerformance(query: CashierPerformanceDto) {
    const endDate = query.endDate ? new Date(query.endDate) : new Date();
    const startDate = query.startDate
      ? new Date(query.startDate)
      : new Date(endDate.getTime() - 30 * 24 * 60 * 60 * 1000);

    const rows = await this.prisma.$queryRaw<
      {
        cashier_id: number;
        email: string;
        display_name: string | null;
        total_orders: bigint;
        total_sales: number;
        avg_order: number;
        active_days: bigint;
      }[]
    >`
      SELECT
        u.id AS cashier_id,
        u.email,
        u.display_name,
        COUNT(o.id)::bigint AS total_orders,
        COALESCE(SUM(o.total), 0)::numeric AS total_sales,
        COALESCE(AVG(o.total), 0)::numeric AS avg_order,
        COUNT(DISTINCT DATE(o.created_at))::bigint AS active_days
      FROM users u
      LEFT JOIN orders o ON o.cashier_id = u.id
        AND o.created_at >= ${startDate}
        AND o.created_at <= ${endDate}
        AND o.status != 'CANCELLED'
      WHERE u.role IN ('CASHIER', 'MANAGER', 'ADMIN')
        AND u.is_active = true
      GROUP BY u.id, u.email, u.display_name
      ORDER BY total_sales DESC
    `;

    return rows.map((r) => ({
      cashierId: r.cashier_id,
      email: r.email,
      displayName: r.display_name,
      totalOrders: Number(r.total_orders),
      totalSales: Number(r.total_sales),
      avgOrderValue: Number(r.avg_order),
      activeDays: Number(r.active_days),
    }));
  }

  private resolveDateRange(
    period: string,
    startStr?: string,
    endStr?: string,
  ): { startDate: Date; endDate: Date } {
    const now = new Date();
    let startDate: Date;
    let endDate = endStr ? new Date(endStr) : now;

    if (startStr) {
      startDate = new Date(startStr);
    } else {
      switch (period) {
        case 'weekly':
          startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
          break;
        case 'monthly':
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
          break;
        case 'daily':
        default:
          startDate = new Date(now);
          startDate.setHours(0, 0, 0, 0);
          break;
      }
    }
    return { startDate, endDate };
  }
}
