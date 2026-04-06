import {
  Injectable,
  UnauthorizedException,
  ConflictException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { SignupDto } from './dto/signup.dto';
import { LoginDto } from './dto/login.dto';
import { JwtPayload } from '../common/decorators/current-user.decorator';

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService,
  ) { }

  async signup(dto: SignupDto) {
    const exists = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (exists) throw new ConflictException('Email already registered');

    const hash = await bcrypt.hash(dto.password, 12);
    const role = dto.role ? (dto.role.toUpperCase() as any) : 'CASHIER';
    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        passwordHash: hash,
        businessName: dto.businessName,
        displayName: dto.displayName,
        role,
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

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (!user || !user.isActive) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) throw new UnauthorizedException('Invalid credentials');

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

  async refresh(userId: number, refreshToken: string) {
    const tokenHash = await bcrypt.hash(refreshToken, 10);

    // Find any valid refresh token for this user
    const storedTokens = await this.prisma.refreshToken.findMany({
      where: { userId, expiresAt: { gt: new Date() } },
    });

    let valid = false;
    let matchedTokenId: number | null = null;
    for (const stored of storedTokens) {
      if (await bcrypt.compare(refreshToken, stored.tokenHash)) {
        valid = true;
        matchedTokenId = stored.id;
        break;
      }
    }

    if (!valid || !matchedTokenId) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    // Delete the used token (rotation)
    await this.prisma.refreshToken.delete({ where: { id: matchedTokenId } });

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.isActive) {
      throw new UnauthorizedException('User inactive');
    }

    const tokens = await this.generateTokens({
      sub: user.id,
      email: user.email,
      role: user.role,
    });
    await this.storeRefreshToken(user.id, tokens.refreshToken);

    return tokens;
  }

  async logout(userId: number) {
    await this.prisma.refreshToken.deleteMany({ where: { userId } });
  }

  private async generateTokens(payload: JwtPayload): Promise<TokenPair> {
    const [accessToken, refreshToken] = await Promise.all([
      this.jwt.signAsync(payload, {
        secret: this.config.get<string>('jwt.accessSecret'),
        expiresIn: this.config.get<string>('jwt.accessExpiration'),
      }),
      this.jwt.signAsync(payload, {
        secret: this.config.get<string>('jwt.refreshSecret'),
        expiresIn: this.config.get<string>('jwt.refreshExpiration'),
      }),
    ]);
    return { accessToken, refreshToken };
  }

  private async storeRefreshToken(userId: number, token: string) {
    const hash = await bcrypt.hash(token, 10);
    const expDays = parseInt(
      this.config.get<string>('jwt.refreshExpiration')?.replace('d', '') || '7',
      10,
    );
    await this.prisma.refreshToken.create({
      data: {
        userId,
        tokenHash: hash,
        expiresAt: new Date(Date.now() + expDays * 24 * 60 * 60 * 1000),
      },
    });
  }

  private sanitizeUser(user: Record<string, unknown>) {
    const { passwordHash, ...safe } = user as Record<string, unknown> & {
      passwordHash: string;
    };
    return safe;
  }
}
