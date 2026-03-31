import { Role } from '@prisma/client';
export declare class CreateUserDto {
    email: string;
    password: string;
    businessName?: string;
    displayName?: string;
    role?: Role;
}
