import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { SalesReportDto, TopProductsDto, RevenueDto, InventoryReportDto, CashierPerformanceDto } from './dto/report-query.dto';
export declare class ReportsService {
    private prisma;
    constructor(prisma: PrismaService);
    sales(query: SalesReportDto): Promise<{
        summary: {
            totalOrders: number;
            totalRevenue: number | Prisma.Decimal;
            avgOrderValue: number | Prisma.Decimal;
            totalTax: number | Prisma.Decimal;
            totalDiscounts: number | Prisma.Decimal;
        };
        paymentBreakdown: {
            method: import(".prisma/client").$Enums.PaymentMethod;
            count: number;
            total: number | Prisma.Decimal;
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
            revenue: number | Prisma.Decimal;
            subtotal: number | Prisma.Decimal;
            tax: number | Prisma.Decimal;
            discounts: number | Prisma.Decimal;
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
            price: Prisma.Decimal;
            cost: Prisma.Decimal;
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
    private resolveDateRange;
}
