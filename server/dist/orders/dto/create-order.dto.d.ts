import { PaymentMethod } from '@prisma/client';
export declare class OrderItemDto {
    productId: number;
    quantity: number;
    discountAmount?: number;
}
export declare class CreateOrderDto {
    items: OrderItemDto[];
    paymentMethod: PaymentMethod;
    paymentDetails?: Record<string, unknown>;
    notes?: string;
    taxRate?: number;
}
