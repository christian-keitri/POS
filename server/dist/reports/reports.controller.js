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
exports.ReportsController = void 0;
const common_1 = require("@nestjs/common");
const client_1 = require("@prisma/client");
const reports_service_1 = require("./reports.service");
const report_query_dto_1 = require("./dto/report-query.dto");
const roles_decorator_1 = require("../common/decorators/roles.decorator");
let ReportsController = class ReportsController {
    constructor(reportsService) {
        this.reportsService = reportsService;
    }
    sales(query) {
        return this.reportsService.sales(query);
    }
    topProducts(query) {
        return this.reportsService.topProducts(query);
    }
    revenue(query) {
        return this.reportsService.revenue(query);
    }
    inventory(query) {
        return this.reportsService.inventory(query);
    }
    cashierPerformance(query) {
        return this.reportsService.cashierPerformance(query);
    }
};
exports.ReportsController = ReportsController;
__decorate([
    (0, common_1.Get)('sales'),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [report_query_dto_1.SalesReportDto]),
    __metadata("design:returntype", void 0)
], ReportsController.prototype, "sales", null);
__decorate([
    (0, common_1.Get)('top-products'),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [report_query_dto_1.TopProductsDto]),
    __metadata("design:returntype", void 0)
], ReportsController.prototype, "topProducts", null);
__decorate([
    (0, common_1.Get)('revenue'),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [report_query_dto_1.RevenueDto]),
    __metadata("design:returntype", void 0)
], ReportsController.prototype, "revenue", null);
__decorate([
    (0, common_1.Get)('inventory'),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [report_query_dto_1.InventoryReportDto]),
    __metadata("design:returntype", void 0)
], ReportsController.prototype, "inventory", null);
__decorate([
    (0, common_1.Get)('cashier-performance'),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [report_query_dto_1.CashierPerformanceDto]),
    __metadata("design:returntype", void 0)
], ReportsController.prototype, "cashierPerformance", null);
exports.ReportsController = ReportsController = __decorate([
    (0, common_1.Controller)('reports'),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.MANAGER),
    __metadata("design:paramtypes", [reports_service_1.ReportsService])
], ReportsController);
//# sourceMappingURL=reports.controller.js.map