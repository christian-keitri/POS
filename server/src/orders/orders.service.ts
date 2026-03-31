import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { Prisma, AdjustmentReason } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderDto } from './dto/update-order.dto';
import { QueryOrdersDto } from './dto/query-orders.dto';
import { PaginatedResult } from '../common/interfaces/api-response.interface';

@Injectable()
export class OrdersService {
  constructor(private prisma: PrismaService) {}

  async findAll(query: QueryOrdersDto): Promise<PaginatedResult<unknown>> {
    const {
      page = 1,
      limit = 20,
      sortBy = 'createdAt',
      sortOrder = 'desc',
      userId,
      cashierId,
      status,
      startDate,
      endDate,
    } = query;

    const where: Prisma.OrderWhereInput = {};
    if (userId) where.userId = userId;
    if (cashierId) where.cashierId = cashierId;
    if (status) where.status = status;
    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) where.createdAt.gte = new Date(startDate);
      if (endDate) where.createdAt.lte = new Date(endDate);
    }

    const [data, total] = await Promise.all([
      this.prisma.order.findMany({
        where,
        include: {
          items: true,
          cashier: { select: { id: true, displayName: true, email: true } },
        },
        orderBy: { [sortBy]: sortOrder },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.order.count({ where }),
    ]);

    return {
      data,
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  async findOne(id: number) {
    const order = await this.prisma.order.findUnique({
      where: { id },
      include: {
        items: { include: { product: { select: { id: true, name: true, sku: true } } } },
        cashier: { select: { id: true, displayName: true, email: true } },
        user: { select: { id: true, displayName: true, email: true } },
      },
    });
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  async getStats(cashierId?: number) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const where: Prisma.OrderWhereInput = {
      createdAt: { gte: today },
      status: { not: 'CANCELLED' },
    };
    if (cashierId) where.cashierId = cashierId;

    const [count, agg] = await Promise.all([
      this.prisma.order.count({ where }),
      this.prisma.order.aggregate({ where, _sum: { total: true } }),
    ]);

    return {
      todayOrders: count,
      todayRevenue: agg._sum.total ?? 0,
    };
  }

  /**
   * Creates an order with atomic stock deduction inside a transaction.
   * Prevents negative stock via check-then-update within the same tx.
   */
  async create(dto: CreateOrderDto, cashierId: number) {
    if (!dto.items.length) {
      throw new BadRequestException('Order must have at least one item');
    }

    return this.prisma.$transaction(async (tx) => {
      // 1. Validate products and stock
      const productIds = dto.items.map((i) => i.productId);
      const products = await tx.product.findMany({
        where: { id: { in: productIds }, isActive: true },
      });

      const productMap = new Map(products.map((p) => [p.id, p]));
      for (const item of dto.items) {
        const product = productMap.get(item.productId);
        if (!product) {
          throw new BadRequestException(
            `Product ${item.productId} not found or inactive`,
          );
        }
        if (product.stock < item.quantity) {
          throw new BadRequestException(
            `Insufficient stock for "${product.name}" (available: ${product.stock}, requested: ${item.quantity})`,
          );
        }
      }

      // 2. Calculate totals
      const taxRate = dto.taxRate ?? 0;
      let subtotal = 0;
      let totalDiscount = 0;

      const itemsData = dto.items.map((item) => {
        const product = productMap.get(item.productId)!;
        const lineSubtotal = Number(product.price) * item.quantity;
        const discount = item.discountAmount ?? 0;
        subtotal += lineSubtotal;
        totalDiscount += discount;

        return {
          productId: product.id,
          productName: product.name,
          quantity: item.quantity,
          unitPrice: product.price,
          subtotal: lineSubtotal,
          discountAmount: discount,
        };
      });

      const taxAmount = subtotal * (taxRate / 100);
      const total = subtotal + taxAmount - totalDiscount;

      // 3. Generate order number
      const orderNumber = this.generateOrderNumber();

      // 4. Create order
      const order = await tx.order.create({
        data: {
          orderNumber,
          cashierId,
          subtotal,
          taxAmount,
          discountAmount: totalDiscount,
          total,
          paymentMethod: dto.paymentMethod,
          paymentDetails: dto.paymentDetails as unknown as Prisma.InputJsonValue ?? undefined,
          notes: dto.notes,
          items: { create: itemsData },
        },
        include: { items: true },
      });

      // 5. Deduct stock + create audit trail (atomically within tx)
      for (const item of dto.items) {
        const product = productMap.get(item.productId)!;
        const newStock = product.stock - item.quantity;

        await tx.product.update({
          where: { id: item.productId },
          data: { stock: newStock },
        });

        await tx.stockAdjustment.create({
          data: {
            productId: item.productId,
            userId: cashierId,
            quantityChange: -item.quantity,
            oldStock: product.stock,
            newStock,
            reason: AdjustmentReason.SALE,
            referenceType: 'order',
            referenceId: order.id,
          },
        });
      }

      return order;
    });
  }

  async update(id: number, dto: UpdateOrderDto) {
    await this.findOne(id);
    const data: Prisma.OrderUpdateInput = {};
    if (dto.status) data.status = dto.status;
    if (dto.paymentMethod) data.paymentMethod = dto.paymentMethod;
    if (dto.notes !== undefined) data.notes = dto.notes;
    if (dto.paymentDetails) {
      data.paymentDetails = dto.paymentDetails as unknown as Prisma.InputJsonValue;
    }
    return this.prisma.order.update({
      where: { id },
      data,
      include: { items: true },
    });
  }

  async getReceipt(id: number) {
    const order = await this.prisma.order.findUnique({
      where: { id },
      include: {
        items: true,
        cashier: { select: { displayName: true, businessName: true } },
      },
    });
    if (!order) throw new NotFoundException('Order not found');

    return {
      orderNumber: order.orderNumber,
      businessName: order.cashier?.businessName ?? 'POS Store',
      cashier: order.cashier?.displayName ?? 'Unknown',
      date: order.createdAt,
      items: order.items.map((i) => ({
        name: i.productName,
        qty: i.quantity,
        price: i.unitPrice,
        subtotal: i.subtotal,
        discount: i.discountAmount,
      })),
      subtotal: order.subtotal,
      tax: order.taxAmount,
      discount: order.discountAmount,
      total: order.total,
      paymentMethod: order.paymentMethod,
      status: order.status,
    };
  }

  private generateOrderNumber(): string {
    const now = new Date();
    const y = String(now.getFullYear()).slice(-2);
    const m = String(now.getMonth() + 1).padStart(2, '0');
    const d = String(now.getDate()).padStart(2, '0');
    const rand = String(Math.floor(Math.random() * 10000)).padStart(4, '0');
    return `ORD-${y}${m}${d}-${rand}`;
  }
}
