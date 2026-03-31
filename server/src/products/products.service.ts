import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import * as fs from 'fs';
import * as path from 'path';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { QueryProductsDto } from './dto/query-products.dto';
import { PaginatedResult } from '../common/interfaces/api-response.interface';

@Injectable()
export class ProductsService {
  constructor(private prisma: PrismaService) {}

  async findAll(query: QueryProductsDto): Promise<PaginatedResult<unknown>> {
    const {
      page = 1,
      limit = 20,
      sortBy = 'createdAt',
      sortOrder = 'desc',
      categoryId,
      isActive,
      search,
      barcode,
    } = query;

    const where: Prisma.ProductWhereInput = {};
    if (categoryId) where.categoryId = categoryId;
    if (isActive !== undefined) where.isActive = isActive;
    if (barcode) where.barcode = barcode;
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

  async findOne(id: number) {
    const product = await this.prisma.product.findUnique({
      where: { id },
      include: { category: { select: { id: true, name: true } } },
    });
    if (!product) throw new NotFoundException('Product not found');
    return product;
  }

  async create(dto: CreateProductDto) {
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
    } catch (e) {
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
        throw new ConflictException('SKU already exists');
      }
      throw e;
    }
  }

  async update(id: number, dto: UpdateProductDto) {
    await this.findOne(id);
    try {
      return await this.prisma.product.update({
        where: { id },
        data: dto,
        include: { category: { select: { id: true, name: true } } },
      });
    } catch (e) {
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
        throw new ConflictException('SKU already exists');
      }
      throw e;
    }
  }

  async uploadImage(id: number, file: Express.Multer.File, uploadDir: string) {
    const product = await this.findOne(id);

    // Delete old image if exists
    if (product.imagePath) {
      const oldPath = path.join(uploadDir, product.imagePath);
      if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
    }

    return this.prisma.product.update({
      where: { id },
      data: { imagePath: file.filename },
      include: { category: { select: { id: true, name: true } } },
    });
  }

  async remove(id: number) {
    const hasOrders = await this.prisma.orderItem.count({
      where: { productId: id },
    });
    if (hasOrders > 0) {
      throw new BadRequestException(
        'Cannot delete product with existing orders. Deactivate it instead.',
      );
    }
    return this.prisma.product.delete({ where: { id } });
  }
}
