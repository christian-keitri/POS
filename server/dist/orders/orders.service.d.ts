import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderDto } from './dto/update-order.dto';
import { QueryOrdersDto } from './dto/query-orders.dto';
import { PaginatedResult } from '../common/interfaces/api-response.interface';
export declare class OrdersService {
    private prisma;
    constructor(prisma: PrismaService);
    findAll(query: QueryOrdersDto): Promise<PaginatedResult<unknown>>;
    findOne(id: number): Promise<{
        user: {
            email: string;
            displayName: string | null;
            id: number;
        } | null;
        cashier: {
            email: string;
            displayName: string | null;
            id: number;
        } | null;
        items: ({
            product: {
                id: number;
                name: string;
                sku: string;
            };
        } & {
            id: number;
            createdAt: Date;
            subtotal: Prisma.Decimal;
            discountAmount: Prisma.Decimal;
            productId: number;
            quantity: number;
            orderId: number;
            productName: string;
            unitPrice: Prisma.Decimal;
        })[];
    } & {
        id: number;
        createdAt: Date;
        updatedAt: Date;
        userId: number | null;
        total: Prisma.Decimal;
        orderNumber: string;
        subtotal: Prisma.Decimal;
        taxAmount: Prisma.Decimal;
        discountAmount: Prisma.Decimal;
        status: import(".prisma/client").$Enums.OrderStatus;
        paymentMethod: import(".prisma/client").$Enums.PaymentMethod;
        paymentDetails: Prisma.JsonValue | null;
        notes: string | null;
        cashierId: number | null;
    }>;
    getStats(cashierId?: number): Promise<{
        todayOrders: number;
        todayRevenue: number | Prisma.Decimal;
    }>;
    create(dto: CreateOrderDto, cashierId: number): Promise<{
        items: {
            id: number;
            createdAt: Date;
            subtotal: Prisma.Decimal;
            discountAmount: Prisma.Decimal;
            productId: number;
            quantity: number;
            orderId: number;
            productName: string;
            unitPrice: Prisma.Decimal;
        }[];
    } & {
        id: number;
        createdAt: Date;
        updatedAt: Date;
        userId: number | null;
        total: Prisma.Decimal;
        orderNumber: string;
        subtotal: Prisma.Decimal;
        taxAmount: Prisma.Decimal;
        discountAmount: Prisma.Decimal;
        status: import(".prisma/client").$Enums.OrderStatus;
        paymentMethod: import(".prisma/client").$Enums.PaymentMethod;
        paymentDetails: Prisma.JsonValue | null;
        notes: string | null;
        cashierId: number | null;
    }>;
    update(id: number, dto: UpdateOrderDto): Promise<{
        items: {
            id: number;
            createdAt: Date;
            subtotal: Prisma.Decimal;
            discountAmount: Prisma.Decimal;
            productId: number;
            quantity: number;
            orderId: number;
            productName: string;
            unitPrice: Prisma.Decimal;
        }[];
    } & {
        id: number;
        createdAt: Date;
        updatedAt: Date;
        userId: number | null;
        total: Prisma.Decimal;
        orderNumber: string;
        subtotal: Prisma.Decimal;
        taxAmount: Prisma.Decimal;
        discountAmount: Prisma.Decimal;
        status: import(".prisma/client").$Enums.OrderStatus;
        paymentMethod: import(".prisma/client").$Enums.PaymentMethod;
        paymentDetails: Prisma.JsonValue | null;
        notes: string | null;
        cashierId: number | null;
    }>;
    getReceipt(id: number): Promise<{
        orderNumber: string;
        businessName: string;
        cashier: string;
        date: Date;
        items: {
            name: string;
            qty: number;
            price: Prisma.Decimal;
            subtotal: Prisma.Decimal;
            discount: Prisma.Decimal;
        }[];
        subtotal: Prisma.Decimal;
        tax: Prisma.Decimal;
        discount: Prisma.Decimal;
        total: Prisma.Decimal;
        paymentMethod: import(".prisma/client").$Enums.PaymentMethod;
        status: import(".prisma/client").$Enums.OrderStatus;
    }>;
    private generateOrderNumber;
}
