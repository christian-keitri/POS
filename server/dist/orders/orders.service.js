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
exports.OrdersService = void 0;
const common_1 = require("@nestjs/common");
const client_1 = require("@prisma/client");
const prisma_service_1 = require("../prisma/prisma.service");
let OrdersService = class OrdersService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findAll(query) {
        const { page = 1, limit = 20, sortBy = 'createdAt', sortOrder = 'desc', userId, cashierId, status, startDate, endDate, } = query;
        const where = {};
        if (userId)
            where.userId = userId;
        if (cashierId)
            where.cashierId = cashierId;
        if (status)
            where.status = status;
        if (startDate || endDate) {
            where.createdAt = {};
            if (startDate)
                where.createdAt.gte = new Date(startDate);
            if (endDate)
                where.createdAt.lte = new Date(endDate);
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
    async findOne(id) {
        const order = await this.prisma.order.findUnique({
            where: { id },
            include: {
                items: { include: { product: { select: { id: true, name: true, sku: true } } } },
                cashier: { select: { id: true, displayName: true, email: true } },
                user: { select: { id: true, displayName: true, email: true } },
            },
        });
        if (!order)
            throw new common_1.NotFoundException('Order not found');
        return order;
    }
    async getStats(cashierId) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const where = {
            createdAt: { gte: today },
            status: { not: 'CANCELLED' },
        };
        if (cashierId)
            where.cashierId = cashierId;
        const [count, agg] = await Promise.all([
            this.prisma.order.count({ where }),
            this.prisma.order.aggregate({ where, _sum: { total: true } }),
        ]);
        return {
            todayOrders: count,
            todayRevenue: agg._sum.total ?? 0,
        };
    }
    async create(dto, cashierId) {
        if (!dto.items.length) {
            throw new common_1.BadRequestException('Order must have at least one item');
        }
        return this.prisma.$transaction(async (tx) => {
            const productIds = dto.items.map((i) => i.productId);
            const products = await tx.product.findMany({
                where: { id: { in: productIds }, isActive: true },
            });
            const productMap = new Map(products.map((p) => [p.id, p]));
            for (const item of dto.items) {
                const product = productMap.get(item.productId);
                if (!product) {
                    throw new common_1.BadRequestException(`Product ${item.productId} not found or inactive`);
                }
                if (product.stock < item.quantity) {
                    throw new common_1.BadRequestException(`Insufficient stock for "${product.name}" (available: ${product.stock}, requested: ${item.quantity})`);
                }
            }
            const taxRate = dto.taxRate ?? 0;
            let subtotal = 0;
            let totalDiscount = 0;
            const itemsData = dto.items.map((item) => {
                const product = productMap.get(item.productId);
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
            const orderNumber = this.generateOrderNumber();
            const order = await tx.order.create({
                data: {
                    orderNumber,
                    cashierId,
                    subtotal,
                    taxAmount,
                    discountAmount: totalDiscount,
                    total,
                    paymentMethod: dto.paymentMethod,
                    paymentDetails: dto.paymentDetails ?? undefined,
                    notes: dto.notes,
                    items: { create: itemsData },
                },
                include: { items: true },
            });
            for (const item of dto.items) {
                const product = productMap.get(item.productId);
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
                        reason: client_1.AdjustmentReason.SALE,
                        referenceType: 'order',
                        referenceId: order.id,
                    },
                });
            }
            return order;
        });
    }
    async update(id, dto) {
        await this.findOne(id);
        const data = {};
        if (dto.status)
            data.status = dto.status;
        if (dto.paymentMethod)
            data.paymentMethod = dto.paymentMethod;
        if (dto.notes !== undefined)
            data.notes = dto.notes;
        if (dto.paymentDetails) {
            data.paymentDetails = dto.paymentDetails;
        }
        return this.prisma.order.update({
            where: { id },
            data,
            include: { items: true },
        });
    }
    async getReceipt(id) {
        const order = await this.prisma.order.findUnique({
            where: { id },
            include: {
                items: true,
                cashier: { select: { displayName: true, businessName: true } },
            },
        });
        if (!order)
            throw new common_1.NotFoundException('Order not found');
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
    generateOrderNumber() {
        const now = new Date();
        const y = String(now.getFullYear()).slice(-2);
        const m = String(now.getMonth() + 1).padStart(2, '0');
        const d = String(now.getDate()).padStart(2, '0');
        const rand = String(Math.floor(Math.random() * 10000)).padStart(4, '0');
        return `ORD-${y}${m}${d}-${rand}`;
    }
};
exports.OrdersService = OrdersService;
exports.OrdersService = OrdersService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], OrdersService);
//# sourceMappingURL=orders.service.js.map