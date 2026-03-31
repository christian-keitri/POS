import { IsEnum, IsOptional, IsString } from 'class-validator';
import { OrderStatus, PaymentMethod } from '@prisma/client';

export class UpdateOrderDto {
  @IsOptional()
  @IsEnum(OrderStatus)
  status?: OrderStatus;

  @IsOptional()
  @IsEnum(PaymentMethod)
  paymentMethod?: PaymentMethod;

  @IsOptional()
  paymentDetails?: Record<string, unknown>;

  @IsOptional()
  @IsString()
  notes?: string;
}
