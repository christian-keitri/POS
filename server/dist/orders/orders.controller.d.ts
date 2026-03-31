import { OrdersService } from './orders.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { UpdateOrderDto } from './dto/update-order.dto';
import { QueryOrdersDto } from './dto/query-orders.dto';
import { JwtPayload } from '../common/decorators/current-user.decorator';
export declare class OrdersController {
    private ordersService;
    constructor(ordersService: OrdersService);
    findAll(query: QueryOrdersDto): Promise<import("../common/interfaces/api-response.interface").PaginatedResult<unknown>>;
    getStats(cashierId?: string): Promise<{
        todayOrders: number;
        todayRevenue: number | import("@prisma/client/runtime/library").Decimal;
    }>;
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
            subtotal: import("@prisma/client/runtime/library").Decimal;
            discountAmount: import("@prisma/client/runtime/library").Decimal;
            productId: number;
            quantity: number;
            orderId: number;
            productName: string;
            unitPrice: import("@prisma/client/runtime/library").Decimal;
        })[];
    } & {
        id: number;
        createdAt: Date;
        updatedAt: Date;
        userId: number | null;
        total: import("@prisma/client/runtime/library").Decimal;
        orderNumber: string;
        subtotal: import("@prisma/client/runtime/library").Decimal;
        taxAmount: import("@prisma/client/runtime/library").Decimal;
        discountAmount: import("@prisma/client/runtime/library").Decimal;
        status: import(".prisma/client").$Enums.OrderStatus;
        paymentMethod: import(".prisma/client").$Enums.PaymentMethod;
        paymentDetails: import("@prisma/client/runtime/library").JsonValue | null;
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
            price: import("@prisma/client/runtime/library").Decimal;
            subtotal: import("@prisma/client/runtime/library").Decimal;
            discount: import("@prisma/client/runtime/library").Decimal;
        }[];
        subtotal: import("@prisma/client/runtime/library").Decimal;
        tax: import("@prisma/client/runtime/library").Decimal;
        discount: import("@prisma/client/runtime/library").Decimal;
        total: import("@prisma/client/runtime/library").Decimal;
        paymentMethod: import(".prisma/client").$Enums.PaymentMethod;
        status: import(".prisma/client").$Enums.OrderStatus;
    }>;
    create(dto: CreateOrderDto, user: JwtPayload): Promise<{
        items: {
            id: number;
            createdAt: Date;
            subtotal: import("@prisma/client/runtime/library").Decimal;
            discountAmount: import("@prisma/client/runtime/library").Decimal;
            productId: number;
            quantity: number;
            orderId: number;
            productName: string;
            unitPrice: import("@prisma/client/runtime/library").Decimal;
        }[];
    } & {
        id: number;
        createdAt: Date;
        updatedAt: Date;
        userId: number | null;
        total: import("@prisma/client/runtime/library").Decimal;
        orderNumber: string;
        subtotal: import("@prisma/client/runtime/library").Decimal;
        taxAmount: import("@prisma/client/runtime/library").Decimal;
        discountAmount: import("@prisma/client/runtime/library").Decimal;
        status: import(".prisma/client").$Enums.OrderStatus;
        paymentMethod: import(".prisma/client").$Enums.PaymentMethod;
        paymentDetails: import("@prisma/client/runtime/library").JsonValue | null;
        notes: string | null;
        cashierId: number | null;
    }>;
    update(id: number, dto: UpdateOrderDto): Promise<{
        items: {
            id: number;
            createdAt: Date;
            subtotal: import("@prisma/client/runtime/library").Decimal;
            discountAmount: import("@prisma/client/runtime/library").Decimal;
            productId: number;
            quantity: number;
            orderId: number;
            productName: string;
            unitPrice: import("@prisma/client/runtime/library").Decimal;
        }[];
    } & {
        id: number;
        createdAt: Date;
        updatedAt: Date;
        userId: number | null;
        total: import("@prisma/client/runtime/library").Decimal;
        orderNumber: string;
        subtotal: import("@prisma/client/runtime/library").Decimal;
        taxAmount: import("@prisma/client/runtime/library").Decimal;
        discountAmount: import("@prisma/client/runtime/library").Decimal;
        status: import(".prisma/client").$Enums.OrderStatus;
        paymentMethod: import(".prisma/client").$Enums.PaymentMethod;
        paymentDetails: import("@prisma/client/runtime/library").JsonValue | null;
        notes: string | null;
        cashierId: number | null;
    }>;
}
