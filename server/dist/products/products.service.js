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
exports.ProductsService = void 0;
const common_1 = require("@nestjs/common");
const client_1 = require("@prisma/client");
const fs = require("fs");
const path = require("path");
const prisma_service_1 = require("../prisma/prisma.service");
let ProductsService = class ProductsService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findAll(query) {
        const { page = 1, limit = 20, sortBy = 'createdAt', sortOrder = 'desc', categoryId, isActive, search, barcode, } = query;
        const where = {};
        if (categoryId)
            where.categoryId = categoryId;
        if (isActive !== undefined)
            where.isActive = isActive;
        if (barcode)
            where.barcode = barcode;
        if (search) {
            where.OR = [
                { name: { contains: search, mode: 'insensitive' } },
                { sku: { contains: search, mode: 'insensitive' } },
                { description: { contains: search, mode: 'insensitive' } },
            ];
        }
        const [data, total] = await Promise.all([
            this.prisma.product.findMany({
                where,
                include: { category: { select: { id: true, name: true } } },
                orderBy: { [sortBy]: sortOrder },
                skip: (page - 1) * limit,
                take: limit,
            }),
            this.prisma.product.count({ where }),
        ]);
        return {
            data,
            meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
        };
    }
    async findOne(id) {
        const product = await this.prisma.product.findUnique({
            where: { id },
            include: { category: { select: { id: true, name: true } } },
        });
        if (!product)
            throw new common_1.NotFoundException('Product not found');
        return product;
    }
    async create(dto) {
        try {
            return await this.prisma.product.create({
                data: {
                    name: dto.name,
                    sku: dto.sku,
                    barcode: dto.barcode,
                    description: dto.description,
                    price: dto.price,
                    cost: dto.cost ?? 0,
                    stock: dto.stock ?? 0,
                    lowStockThreshold: dto.lowStockThreshold ?? 10,
                    categoryId: dto.categoryId,
                    isActive: dto.isActive ?? true,
                },
                include: { category: { select: { id: true, name: true } } },
            });
        }
        catch (e) {
            if (e instanceof client_1.Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
                throw new common_1.ConflictException('SKU already exists');
            }
            throw e;
        }
    }
    async update(id, dto) {
        await this.findOne(id);
        try {
            return await this.prisma.product.update({
                where: { id },
                data: dto,
                include: { category: { select: { id: true, name: true } } },
            });
        }
        catch (e) {
            if (e instanceof client_1.Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
                throw new common_1.ConflictException('SKU already exists');
            }
            throw e;
        }
    }
    async uploadImage(id, file, uploadDir) {
        const product = await this.findOne(id);
        if (product.imagePath) {
            const oldPath = path.join(uploadDir, product.imagePath);
            if (fs.existsSync(oldPath))
                fs.unlinkSync(oldPath);
        }
        return this.prisma.product.update({
            where: { id },
            data: { imagePath: file.filename },
            include: { category: { select: { id: true, name: true } } },
        });
    }
    async remove(id) {
        const hasOrders = await this.prisma.orderItem.count({
            where: { productId: id },
        });
        if (hasOrders > 0) {
            throw new common_1.BadRequestException('Cannot delete product with existing orders. Deactivate it instead.');
        }
        return this.prisma.product.delete({ where: { id } });
    }
};
exports.ProductsService = ProductsService;
exports.ProductsService = ProductsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], ProductsService);
//# sourceMappingURL=products.service.js.map