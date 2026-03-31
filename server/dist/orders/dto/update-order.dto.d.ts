import { OrderStatus, PaymentMethod } from '@prisma/client';
export declare class UpdateOrderDto {
    status?: OrderStatus;
    paymentMethod?: PaymentMethod;
    paymentDetails?: Record<string, unknown>;
    notes?: string;
}
