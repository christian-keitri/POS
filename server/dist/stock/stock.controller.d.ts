import { StockService } from './stock.service';
import { AdjustStockDto } from './dto/adjust-stock.dto';
import { QueryAdjustmentsDto } from './dto/query-adjustments.dto';
import { JwtPayload } from '../common/decorators/current-user.decorator';
export declare class StockController {
    private stockService;
    constructor(stockService: StockService);
    getAdjustments(query: QueryAdjustmentsDto): Promise<import("../common/interfaces/api-response.interface").PaginatedResult<unknown>>;
    getAlerts(): Promise<{
        lowStockThreshold: number;
        unitsNeeded: number;
        id: number;
        name: string;
        sku: string;
        stock: number;
        low_stock_threshold: number;
    }[]>;
    adjust(dto: AdjustStockDto, user: JwtPayload): Promise<{
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
}
