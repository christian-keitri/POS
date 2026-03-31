import { AuthService } from './auth.service';
import { SignupDto } from './dto/signup.dto';
import { LoginDto } from './dto/login.dto';
export declare class AuthController {
    private authService;
    constructor(authService: AuthService);
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
    refresh(user: {
        sub: number;
        refreshToken: string;
    }): Promise<import("./auth.service").TokenPair>;
    logout(user: {
        sub: number;
    }): Promise<void>;
}
