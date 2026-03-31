import { CategoriesService } from './categories.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';
import { PaginationDto } from '../common/dto/pagination.dto';
export declare class CategoriesController {
    private categoriesService;
    constructor(categoriesService: CategoriesService);
    findAll(query: PaginationDto): Promise<import("../common/interfaces/api-response.interface").PaginatedResult<unknown>>;
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
