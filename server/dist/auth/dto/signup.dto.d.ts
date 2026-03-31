import { Role } from '@prisma/client';
export declare class SignupDto {
    email: string;
    password: string;
    businessName?: string;
    displayName?: string;
    role?: Role;
}
