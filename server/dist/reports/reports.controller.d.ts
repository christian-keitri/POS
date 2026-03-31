import { ReportsService } from './reports.service';
import { SalesReportDto, TopProductsDto, RevenueDto, InventoryReportDto, CashierPerformanceDto } from './dto/report-query.dto';
export declare class ReportsController {
    private reportsService;
    constructor(reportsService: ReportsService);
    sales(query: SalesReportDto): Promise<{
        summary: {
            totalOrders: number;
            totalRevenue: number | import("@prisma/client/runtime/library").Decimal;
            avgOrderValue: number | import("@prisma/client/runtime/library").Decimal;
            totalTax: number | import("@prisma/client/runtime/library").Decimal;
            totalDiscounts: number | import("@prisma/client/runtime/library").Decimal;
        };
        paymentBreakdown: {
            method: import(".prisma/client").$Enums.PaymentMethod;
            count: number;
            total: number | import("@prisma/client/runtime/library").Decimal;
        }[];
        period: {
            start: Date;
            end: Date;
        };
    }>;
    topProducts(query: TopProductsDto): Promise<{
        productId: number;
        productName: string;
        totalQuantity: number;
        totalRevenue: number;
        orderCount: number;
    }[]>;
    revenue(query: RevenueDto): Promise<{
        data: {
            period: Date;
            orders: number;
            revenue: number;
            avgOrderValue: number;
        }[];
        totals: {
            orders: number;
            revenue: number | import("@prisma/client/runtime/library").Decimal;
            subtotal: number | import("@prisma/client/runtime/library").Decimal;
            tax: number | import("@prisma/client/runtime/library").Decimal;
            discounts: number | import("@prisma/client/runtime/library").Decimal;
        };
    }>;
    inventory(query: InventoryReportDto): Promise<{
        products: {
            id: number;
            name: string;
            sku: string;
            category: string;
            stock: number;
            lowStockThreshold: number;
            price: import("@prisma/client/runtime/library").Decimal;
            cost: import("@prisma/client/runtime/library").Decimal;
            stockValue: number;
            costValue: number;
            potentialProfit: number;
            isLowStock: boolean;
        }[];
        summary: {
            totalProducts: number;
            totalStockValue: number;
            totalCostValue: number;
            totalPotentialProfit: number;
            lowStockCount: number;
        };
    }>;
    cashierPerformance(query: CashierPerformanceDto): Promise<{
        cashierId: number;
        email: string;
        displayName: string | null;
        totalOrders: number;
        totalSales: number;
        avgOrderValue: number;
        activeDays: number;
    }[]>;
}
