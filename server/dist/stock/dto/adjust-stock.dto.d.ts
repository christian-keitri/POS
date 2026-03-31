import { AdjustmentReason } from '@prisma/client';
export declare class AdjustStockDto {
    productId: number;
    quantityChange: number;
    reason: AdjustmentReason;
    notes?: string;
}
