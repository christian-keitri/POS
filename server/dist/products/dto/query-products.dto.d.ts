import { PaginationDto } from '../../common/dto/pagination.dto';
export declare class QueryProductsDto extends PaginationDto {
    categoryId?: number;
    isActive?: boolean;
    search?: string;
    barcode?: string;
}
