import { Role } from '@prisma/client';
export declare class UpdateUserDto {
    email?: string;
    password?: string;
    businessName?: string;
    displayName?: string;
    role?: Role;
    isActive?: boolean;
}
