import { PrismaService } from '../prisma/prisma.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';
import { PaginationDto } from '../common/dto/pagination.dto';
import { PaginatedResult } from '../common/interfaces/api-response.interface';
export declare class CategoriesService {
    private prisma;
    constructor(prisma: PrismaService);
    findAll(query: PaginationDto): Promise<PaginatedResult<unknown>>;
    findOne(id: number): Promise<{
        _count: {
            products: number;
        };
    } & {
        id: number;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        sortOrder: number;
        description: string | null;
    }>;
    create(dto: CreateCategoryDto): Promise<{
        id: number;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        sortOrder: number;
        description: string | null;
    }>;
    update(id: number, dto: UpdateCategoryDto): Promise<{
        id: number;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        sortOrder: number;
        description: string | null;
    }>;
    remove(id: number): Promise<{
        id: number;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        sortOrder: number;
        description: string | null;
    }>;
}
