import { Injectable, BadRequestException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AdjustStockDto } from './dto/adjust-stock.dto';
import { QueryAdjustmentsDto } from './dto/query-adjustments.dto';
import { PaginatedResult } from '../common/interfaces/api-response.interface';

@Injectable()
export class StockService {
  constructor(private prisma: PrismaService) {}

  async getAdjustments(query: QueryAdjustmentsDto): Promise<PaginatedResult<unknown>> {
    const {
      page = 1,
      limit = 20,
      sortBy = 'createdAt',
      sortOrder = 'desc',
      productId,
      userId,
      reason,
      startDate,
      endDate,
    } = query;

    const where: Prisma.StockAdjustmentWhereInput = {};
    if (productId) where.productId = productId;
    if (userId) where.userId = userId;
    if (reason) where.reason = reason;
    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) where.createdAt.gte = new Date(startDate);
      if (endDate) where.createdAt.lte = new Date(endDate);
    }

    const [data, total] = await Promise.all([
      this.prisma.stockAdjustment.findMany({
        where,
        include: {
          product: { select: { id: true, name: true, sku: true } },
          user: { select: { id: true, email: true, displayName: true } },
        },
        orderBy: { [sortBy]: sortOrder },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.stockAdjustment.count({ where }),
    ]);

    return {
      data,
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  /**
   * Adjusts stock atomically within a transaction.
   * Prevents negative stock.
   */
  async adjust(dto: AdjustStockDto, userId: number) {
    // SALE reason is reserved for order creation
    if (dto.reason === 'SALE') {
      throw new BadRequestException('SALE adjustments are created automatically via orders');
    }

    return this.prisma.$transaction(async (tx) => {
      const product = await tx.product.findUnique({
        where: { id: dto.productId },
      });
      if (!product) {
        throw new BadRequestException('Product not found');
      }

      const newStock = product.stock + dto.quantityChange;
      if (newStock < 0) {
        throw new BadRequestException(
          `Adjustment would result in negative stock (current: ${product.stock}, change: ${dto.quantityChange})`,
        );
      }

      await tx.product.update({
        where: { id: dto.productId },
        data: { stock: newStock },
      });

      const adjustment = await tx.stockAdjustment.create({
        data: {
          productId: dto.productId,
          userId,
          quantityChange: dto.quantityChange,
          oldStock: product.stock,
          newStock,
          reason: dto.reason,
          notes: dto.notes,
        },
        include: {
          product: { select: { id: true, name: true, sku: true } },
        },
      });

      return adjustment;
    });
  }

  async getAlerts() {
    const products = await this.prisma.product.findMany({
      where: {
        isActive: true,
        stock: { lte: this.prisma.product.fields.lowStockThreshold as unknown as number },
      },
      select: {
        id: true,
        name: true,
        sku: true,
        stock: true,
        lowStockThreshold: true,
      },
      orderBy: { stock: 'asc' },
    });

    // Prisma doesn't support column-to-column comparison directly,
    // so we filter in application layer
    const lowStockProducts = await this.prisma.$queryRaw<
      { id: number; name: string; sku: string; stock: number; low_stock_threshold: number }[]
    >`
      SELECT id, name, sku, stock, low_stock_threshold
      FROM products
      WHERE is_active = true AND stock <= low_stock_threshold
      ORDER BY stock ASC
    `;

    return lowStockProducts.map((p) => ({
      ...p,
      lowStockThreshold: p.low_stock_threshold,
      unitsNeeded: p.low_stock_threshold - p.stock,
    }));
  }
}
