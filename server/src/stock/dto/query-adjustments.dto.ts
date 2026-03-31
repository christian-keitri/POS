import { IsOptional, IsInt, IsEnum, IsDateString } from 'class-validator';
import { Type } from 'class-transformer';
import { AdjustmentReason } from '@prisma/client';
import { PaginationDto } from '../../common/dto/pagination.dto';

export class QueryAdjustmentsDto extends PaginationDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  productId?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  userId?: number;

  @IsOptional()
  @IsEnum(AdjustmentReason)
  reason?: AdjustmentReason;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;
}
