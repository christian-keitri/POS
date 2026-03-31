import { Controller, Get, Post, Body, Query } from '@nestjs/common';
import { Role } from '@prisma/client';
import { StockService } from './stock.service';
import { AdjustStockDto } from './dto/adjust-stock.dto';
import { QueryAdjustmentsDto } from './dto/query-adjustments.dto';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';

@Controller('stock')
export class StockController {
  constructor(private stockService: StockService) {}

  @Get('adjustments')
  getAdjustments(@Query() query: QueryAdjustmentsDto) {
    return this.stockService.getAdjustments(query);
  }

  @Get('alerts')
  getAlerts() {
    return this.stockService.getAlerts();
  }

  @Post('adjust')
  @Roles(Role.ADMIN, Role.MANAGER)
  adjust(@Body() dto: AdjustStockDto, @CurrentUser() user: JwtPayload) {
    return this.stockService.adjust(dto, user.sub);
  }
}
