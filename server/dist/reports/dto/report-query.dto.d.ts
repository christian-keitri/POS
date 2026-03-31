export declare class SalesReportDto {
    period?: string;
    startDate?: string;
    endDate?: string;
    cashierId?: number;
}
export declare class TopProductsDto {
    period?: string;
    startDate?: string;
    endDate?: string;
    limit?: number;
}
export declare class RevenueDto {
    groupBy?: string;
    startDate?: string;
    endDate?: string;
}
export declare class InventoryReportDto {
    categoryId?: number;
    lowStockOnly?: string;
}
export declare class CashierPerformanceDto {
    startDate?: string;
    endDate?: string;
}
