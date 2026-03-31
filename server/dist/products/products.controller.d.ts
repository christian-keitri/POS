import { ConfigService } from '@nestjs/config';
import { ProductsService } from './products.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { QueryProductsDto } from './dto/query-products.dto';
export declare class ProductsController {
    private productsService;
    private config;
    constructor(productsService: ProductsService, config: ConfigService);
    findAll(query: QueryProductsDto): Promise<import("../common/interfaces/api-response.interface").PaginatedResult<unknown>>;
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
        price: import("@prisma/client/runtime/library").Decimal;
        cost: import("@prisma/client/runtime/library").Decimal;
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
        price: import("@prisma/client/runtime/library").Decimal;
        cost: import("@prisma/client/runtime/library").Decimal;
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
        price: import("@prisma/client/runtime/library").Decimal;
        cost: import("@prisma/client/runtime/library").Decimal;
        stock: number;
        lowStockThreshold: number;
        categoryId: number | null;
        imagePath: string | null;
    }>;
    uploadImage(id: number, file: Express.Multer.File): Promise<{
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
        price: import("@prisma/client/runtime/library").Decimal;
        cost: import("@prisma/client/runtime/library").Decimal;
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
        price: import("@prisma/client/runtime/library").Decimal;
        cost: import("@prisma/client/runtime/library").Decimal;
        stock: number;
        lowStockThreshold: number;
        categoryId: number | null;
        imagePath: string | null;
    }>;
}
