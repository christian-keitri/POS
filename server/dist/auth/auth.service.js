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
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const jwt_1 = require("@nestjs/jwt");
const bcrypt = require("bcrypt");
const prisma_service_1 = require("../prisma/prisma.service");
let AuthService = class AuthService {
    constructor(prisma, jwt, config) {
        this.prisma = prisma;
        this.jwt = jwt;
        this.config = config;
    }
    async signup(dto) {
        const exists = await this.prisma.user.findUnique({
            where: { email: dto.email },
        });
        if (exists)
            throw new common_1.ConflictException('Email already registered');
        const hash = await bcrypt.hash(dto.password, 12);
        const user = await this.prisma.user.create({
            data: {
                email: dto.email,
                passwordHash: hash,
                businessName: dto.businessName,
                displayName: dto.displayName,
                role: dto.role,
            },
        });
        const tokens = await this.generateTokens({
            sub: user.id,
            email: user.email,
            role: user.role,
        });
        await this.storeRefreshToken(user.id, tokens.refreshToken);
        return {
            user: this.sanitizeUser(user),
            ...tokens,
        };
    }
    async login(dto) {
        const user = await this.prisma.user.findUnique({
            where: { email: dto.email },
        });
        if (!user || !user.isActive) {
            throw new common_1.UnauthorizedException('Invalid credentials');
        }
        const valid = await bcrypt.compare(dto.password, user.passwordHash);
        if (!valid)
            throw new common_1.UnauthorizedException('Invalid credentials');
        const tokens = await this.generateTokens({
            sub: user.id,
            email: user.email,
            role: user.role,
        });
        await this.storeRefreshToken(user.id, tokens.refreshToken);
        return {
            user: this.sanitizeUser(user),
            ...tokens,
        };
    }
    async refresh(userId, refreshToken) {
        const tokenHash = await bcrypt.hash(refreshToken, 10);
        const storedTokens = await this.prisma.refreshToken.findMany({
            where: { userId, expiresAt: { gt: new Date() } },
        });
        let valid = false;
        let matchedTokenId = null;
        for (const stored of storedTokens) {
            if (await bcrypt.compare(refreshToken, stored.tokenHash)) {
                valid = true;
                matchedTokenId = stored.id;
                break;
            }
        }
        if (!valid || !matchedTokenId) {
            throw new common_1.UnauthorizedException('Invalid refresh token');
        }
        await this.prisma.refreshToken.delete({ where: { id: matchedTokenId } });
        const user = await this.prisma.user.findUnique({ where: { id: userId } });
        if (!user || !user.isActive) {
            throw new common_1.UnauthorizedException('User inactive');
        }
        const tokens = await this.generateTokens({
            sub: user.id,
            email: user.email,
            role: user.role,
        });
        await this.storeRefreshToken(user.id, tokens.refreshToken);
        return tokens;
    }
    async logout(userId) {
        await this.prisma.refreshToken.deleteMany({ where: { userId } });
    }
    async generateTokens(payload) {
        const [accessToken, refreshToken] = await Promise.all([
            this.jwt.signAsync(payload, {
                secret: this.config.get('jwt.accessSecret'),
                expiresIn: this.config.get('jwt.accessExpiration'),
            }),
            this.jwt.signAsync(payload, {
                secret: this.config.get('jwt.refreshSecret'),
                expiresIn: this.config.get('jwt.refreshExpiration'),
            }),
        ]);
        return { accessToken, refreshToken };
    }
    async storeRefreshToken(userId, token) {
        const hash = await bcrypt.hash(token, 10);
        const expDays = parseInt(this.config.get('jwt.refreshExpiration')?.replace('d', '') || '7', 10);
        await this.prisma.refreshToken.create({
            data: {
                userId,
                tokenHash: hash,
                expiresAt: new Date(Date.now() + expDays * 24 * 60 * 60 * 1000),
            },
        });
    }
    sanitizeUser(user) {
        const { passwordHash, ...safe } = user;
        return safe;
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        jwt_1.JwtService,
        config_1.ConfigService])
], AuthService);
//# sourceMappingURL=auth.service.js.map