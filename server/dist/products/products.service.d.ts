import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { QueryProductsDto } from './dto/query-products.dto';
import { PaginatedResult } from '../common/interfaces/api-response.interface';
export declare class ProductsService {
    private prisma;
    constructor(prisma: PrismaService);
    findAll(query: QueryProductsDto): Promise<PaginatedResult<unknown>>;
    findOne(id: number): Promise<{
        category: {
            id: number;
            name: string;
        } | null;
    } & {
        id: number;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        description: string | null;
        sku: string;
        barcode: string | null;
        price: Prisma.Decimal;
        cost: Prisma.Decimal;
        stock: number;
        lowStockThreshold: number;
        categoryId: number | null;
        imagePath: string | null;
    }>;
    create(dto: CreateProductDto): Promise<{
        category: {
            id: number;
            name: string;
        } | null;
    } & {
        id: number;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        description: string | null;
        sku: string;
        barcode: string | null;
        price: Prisma.Decimal;
        cost: Prisma.Decimal;
        stock: number;
        lowStockThreshold: number;
        categoryId: number | null;
        imagePath: string | null;
    }>;
    update(id: number, dto: UpdateProductDto): Promise<{
        category: {
            id: number;
            name: string;
        } | null;
    } & {
        id: number;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        description: string | null;
        sku: string;
        barcode: string | null;
        price: Prisma.Decimal;
        cost: Prisma.Decimal;
        stock: number;
        lowStockThreshold: number;
        categoryId: number | null;
        imagePath: string | null;
    }>;
    uploadImage(id: number, file: Express.Multer.File, uploadDir: string): Promise<{
        category: {
            id: number;
            name: string;
        } | null;
    } & {
        id: number;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        description: string | null;
        sku: string;
        barcode: string | null;
        price: Prisma.Decimal;
        cost: Prisma.Decimal;
        stock: number;
        lowStockThreshold: number;
        categoryId: number | null;
        imagePath: string | null;
    }>;
    remove(id: number): Promise<{
        id: number;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        description: string | null;
        sku: string;
        barcode: string | null;
        price: Prisma.Decimal;
        cost: Prisma.Decimal;
        stock: number;
        lowStockThreshold: number;
        categoryId: number | null;
        imagePath: string | null;
    }>;
}
