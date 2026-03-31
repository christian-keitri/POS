import { AdjustmentReason } from '@prisma/client';
import { PaginationDto } from '../../common/dto/pagination.dto';
export declare class QueryAdjustmentsDto extends PaginationDto {
    productId?: number;
    userId?: number;
    reason?: AdjustmentReason;
    startDate?: string;
    endDate?: string;
}
