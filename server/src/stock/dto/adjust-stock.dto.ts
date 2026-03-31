import { IsEnum, IsInt, IsOptional, IsString, NotEquals } from 'class-validator';
import { Type } from 'class-transformer';
import { AdjustmentReason } from '@prisma/client';

export class AdjustStockDto {
  @Type(() => Number)
  @IsInt()
  productId: number;

  @Type(() => Number)
  @IsInt()
  @NotEquals(0, { message: 'quantityChange cannot be zero' })
  quantityChange: number;

  @IsEnum(AdjustmentReason, {
    message: 'reason must be one of: PURCHASE, ADJUSTMENT, DAMAGE, RETURN',
  })
  reason: AdjustmentReason;

  @IsOptional()
  @IsString()
  notes?: string;
}
