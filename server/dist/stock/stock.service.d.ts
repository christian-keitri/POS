import { PrismaService } from '../prisma/prisma.service';
import { AdjustStockDto } from './dto/adjust-stock.dto';
import { QueryAdjustmentsDto } from './dto/query-adjustments.dto';
import { PaginatedResult } from '../common/interfaces/api-response.interface';
export declare class StockService {
    private prisma;
    constructor(prisma: PrismaService);
    getAdjustments(query: QueryAdjustmentsDto): Promise<PaginatedResult<unknown>>;
    adjust(dto: AdjustStockDto, userId: number): Promise<{
        product: {
            id: number;
            name: string;
            sku: string;
        };
    } & {
        id: number;
        createdAt: Date;
        userId: number | null;
        notes: string | null;
        quantityChange: number;
        oldStock: number;
        newStock: number;
        reason: import(".prisma/client").$Enums.AdjustmentReason;
        referenceType: string | null;
        referenceId: number | null;
        productId: number;
    }>;
    getAlerts(): Promise<{
        lowStockThreshold: number;
        unitsNeeded: number;
        id: number;
        name: string;
        sku: string;
        stock: number;
        low_stock_threshold: number;
    }[]>;
}
