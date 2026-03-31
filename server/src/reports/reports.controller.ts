import { Controller, Get, Query } from '@nestjs/common';
import { Role } from '@prisma/client';
import { ReportsService } from './reports.service';
import {
  SalesReportDto,
  TopProductsDto,
  RevenueDto,
  InventoryReportDto,
  CashierPerformanceDto,
} from './dto/report-query.dto';
import { Roles } from '../common/decorators/roles.decorator';

@Controller('reports')
@Roles(Role.ADMIN, Role.MANAGER)
export class ReportsController {
  constructor(private reportsService: ReportsService) {}

  @Get('sales')
  sales(@Query() query: SalesReportDto) {
    return this.reportsService.sales(query);
  }

  @Get('top-products')
  topProducts(@Query() query: TopProductsDto) {
    return this.reportsService.topProducts(query);
  }

  @Get('revenue')
  revenue(@Query() query: RevenueDto) {
    return this.reportsService.revenue(query);
  }

  @Get('inventory')
  inventory(@Query() query: InventoryReportDto) {
    return this.reportsService.inventory(query);
  }

  @Get('cashier-performance')
  cashierPerformance(@Query() query: CashierPerformanceDto) {
    return this.reportsService.cashierPerformance(query);
  }
}
