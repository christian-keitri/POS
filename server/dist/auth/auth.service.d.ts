import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { SignupDto } from './dto/signup.dto';
import { LoginDto } from './dto/login.dto';
export interface TokenPair {
    accessToken: string;
    refreshToken: string;
}
export declare class AuthService {
    private prisma;
    private jwt;
    private config;
    constructor(prisma: PrismaService, jwt: JwtService, config: ConfigService);
    signup(dto: SignupDto): Promise<{
        accessToken: string;
        refreshToken: string;
        user: {
            [x: string]: unknown;
        };
    }>;
    login(dto: LoginDto): Promise<{
        accessToken: string;
        refreshToken: string;
        user: {
            [x: string]: unknown;
        };
    }>;
    refresh(userId: number, refreshToken: string): Promise<TokenPair>;
    logout(userId: number): Promise<void>;
    private generateTokens;
    private storeRefreshToken;
    private sanitizeUser;
}
