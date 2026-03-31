import { IsOptional, IsDateString, IsEnum, IsInt, IsIn } from 'class-validator';
import { Type } from 'class-transformer';

export class SalesReportDto {
  @IsOptional()
  @IsIn(['daily', 'weekly', 'monthly', 'custom'])
  period?: string = 'daily';

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  cashierId?: number;
}

export class TopProductsDto {
  @IsOptional()
  @IsIn(['daily', 'weekly', 'monthly', 'custom'])
  period?: string = 'monthly';

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  limit?: number = 10;
}

export class RevenueDto {
  @IsOptional()
  @IsIn(['daily', 'weekly', 'monthly'])
  groupBy?: string = 'daily';

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;
}

export class InventoryReportDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  categoryId?: number;

  @IsOptional()
  @IsIn(['true', 'false'])
  lowStockOnly?: string;
}

export class CashierPerformanceDto {
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;
}
