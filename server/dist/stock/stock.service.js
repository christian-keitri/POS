"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.StockService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let StockService = class StockService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getAdjustments(query) {
        const { page = 1, limit = 20, sortBy = 'createdAt', sortOrder = 'desc', productId, userId, reason, startDate, endDate, } = query;
        const where = {};
        if (productId)
            where.productId = productId;
        if (userId)
            where.userId = userId;
        if (reason)
            where.reason = reason;
        if (startDate || endDate) {
            where.createdAt = {};
            if (startDate)
                where.createdAt.gte = new Date(startDate);
            if (endDate)
                where.createdAt.lte = new Date(endDate);
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
    async adjust(dto, userId) {
        if (dto.reason === 'SALE') {
            throw new common_1.BadRequestException('SALE adjustments are created automatically via orders');
        }
        return this.prisma.$transaction(async (tx) => {
            const product = await tx.product.findUnique({
                where: { id: dto.productId },
            });
            if (!product) {
                throw new common_1.BadRequestException('Product not found');
            }
            const newStock = product.stock + dto.quantityChange;
            if (newStock < 0) {
                throw new common_1.BadRequestException(`Adjustment would result in negative stock (current: ${product.stock}, change: ${dto.quantityChange})`);
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
                stock: { lte: this.prisma.product.fields.lowStockThreshold },
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
        const lowStockProducts = await this.prisma.$queryRaw `
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
};
exports.StockService = StockService;
exports.StockService = StockService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], StockService);
//# sourceMappingURL=stock.service.js.map