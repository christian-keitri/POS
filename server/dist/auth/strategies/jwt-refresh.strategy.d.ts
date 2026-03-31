import { ConfigService } from '@nestjs/config';
import { Strategy } from 'passport-jwt';
import { Request } from 'express';
import { JwtPayload } from '../../common/decorators/current-user.decorator';
declare const JwtRefreshStrategy_base: new (...args: any[]) => Strategy;
export declare class JwtRefreshStrategy extends JwtRefreshStrategy_base {
    constructor(config: ConfigService);
    validate(req: Request, payload: JwtPayload): {
        refreshToken: string | undefined;
        sub: number;
        email: string;
        role: string;
    };
}
export {};
