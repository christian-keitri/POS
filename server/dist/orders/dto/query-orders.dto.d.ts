import { OrderStatus } from '@prisma/client';
import { PaginationDto } from '../../common/dto/pagination.dto';
export declare class QueryOrdersDto extends PaginationDto {
    userId?: number;
    cashierId?: number;
    status?: OrderStatus;
    startDate?: string;
    endDate?: string;
}
