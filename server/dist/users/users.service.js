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
Object.defineProperty(exports, "__esModule", { value: true });
exports.UsersService = void 0;
const common_1 = require("@nestjs/common");
const bcrypt = require("bcrypt");
const prisma_service_1 = require("../prisma/prisma.service");
const USER_SELECT = {
    id: true,
    email: true,
    businessName: true,
    displayName: true,
    role: true,
    isActive: true,
    createdAt: true,
    updatedAt: true,
};
let UsersService = class UsersService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findAll(query) {
        const { page = 1, limit = 20, sortBy = 'createdAt', sortOrder = 'desc', role, isActive } = query;
        const where = {};
        if (role)
            where.role = role;
        if (isActive !== undefined)
            where.isActive = isActive;
        const [data, total] = await Promise.all([
            this.prisma.user.findMany({
                where,
                select: USER_SELECT,
                orderBy: { [sortBy]: sortOrder },
                skip: (page - 1) * limit,
                take: limit,
            }),
            this.prisma.user.count({ where }),
        ]);
        return {
            data,
            meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
        };
    }
    async findOne(id) {
        const user = await this.prisma.user.findUnique({
            where: { id },
            select: USER_SELECT,
        });
        if (!user)
            throw new common_1.NotFoundException('User not found');
        return user;
    }
    async create(dto) {
        const exists = await this.prisma.user.findUnique({
            where: { email: dto.email },
        });
        if (exists)
            throw new common_1.ConflictException('Email already registered');
        const hash = await bcrypt.hash(dto.password, 12);
        return this.prisma.user.create({
            data: {
                email: dto.email,
                passwordHash: hash,
                businessName: dto.businessName,
                displayName: dto.displayName,
                role: dto.role,
            },
            select: USER_SELECT,
        });
    }
    async update(id, dto) {
        await this.findOne(id);
        const data = {};
        if (dto.email)
            data.email = dto.email;
        if (dto.businessName !== undefined)
            data.businessName = dto.businessName;
        if (dto.displayName !== undefined)
            data.displayName = dto.displayName;
        if (dto.role)
            data.role = dto.role;
        if (dto.isActive !== undefined)
            data.isActive = dto.isActive;
        if (dto.password)
            data.passwordHash = await bcrypt.hash(dto.password, 12);
        return this.prisma.user.update({
            where: { id },
            data,
            select: USER_SELECT,
        });
    }
    async deactivate(id) {
        await this.findOne(id);
        return this.prisma.user.update({
            where: { id },
            data: { isActive: false },
            select: USER_SELECT,
        });
    }
};
exports.UsersService = UsersService;
exports.UsersService = UsersService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], UsersService);
//# sourceMappingURL=users.service.js.map