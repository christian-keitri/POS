"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.StockController = void 0;
const common_1 = require("@nestjs/common");
const client_1 = require("@prisma/client");
const stock_service_1 = require("./stock.service");
const adjust_stock_dto_1 = require("./dto/adjust-stock.dto");
const query_adjustments_dto_1 = require("./dto/query-adjustments.dto");
const current_user_decorator_1 = require("../common/decorators/current-user.decorator");
const roles_decorator_1 = require("../common/decorators/roles.decorator");
let StockController = class StockController {
    constructor(stockService) {
        this.stockService = stockService;
    }
    getAdjustments(query) {
        return this.stockService.getAdjustments(query);
    }
    getAlerts() {
        return this.stockService.getAlerts();
    }
    adjust(dto, user) {
        return this.stockService.adjust(dto, user.sub);
    }
};
exports.StockController = StockController;
__decorate([
    (0, common_1.Get)('adjustments'),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [query_adjustments_dto_1.QueryAdjustmentsDto]),
    __metadata("design:returntype", void 0)
], StockController.prototype, "getAdjustments", null);
__decorate([
    (0, common_1.Get)('alerts'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], StockController.prototype, "getAlerts", null);
__decorate([
    (0, common_1.Post)('adjust'),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.MANAGER),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [adjust_stock_dto_1.AdjustStockDto, Object]),
    __metadata("design:returntype", void 0)
], StockController.prototype, "adjust", null);
exports.StockController = StockController = __decorate([
    (0, common_1.Controller)('stock'),
    __metadata("design:paramtypes", [stock_service_1.StockService])
], StockController);
//# sourceMappingURL=stock.controller.js.map