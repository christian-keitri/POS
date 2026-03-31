import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { QueryUsersDto } from './dto/query-users.dto';
import { PaginatedResult } from '../common/interfaces/api-response.interface';
export declare class UsersService {
    private prisma;
    constructor(prisma: PrismaService);
    findAll(query: QueryUsersDto): Promise<PaginatedResult<unknown>>;
    findOne(id: number): Promise<{
        email: string;
        businessName: string | null;
        displayName: string | null;
        role: import(".prisma/client").$Enums.Role;
        id: number;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
    }>;
    create(dto: CreateUserDto): Promise<{
        email: string;
        businessName: string | null;
        displayName: string | null;
        role: import(".prisma/client").$Enums.Role;
        id: number;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
    }>;
    update(id: number, dto: UpdateUserDto): Promise<{
        email: string;
        businessName: string | null;
        displayName: string | null;
        role: import(".prisma/client").$Enums.Role;
        id: number;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
    }>;
    deactivate(id: number): Promise<{
        email: string;
        businessName: string | null;
        displayName: string | null;
        role: import(".prisma/client").$Enums.Role;
        id: number;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
    }>;
}
