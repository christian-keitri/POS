import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { QueryUsersDto } from './dto/query-users.dto';
export declare class UsersController {
    private usersService;
    constructor(usersService: UsersService);
    findAll(query: QueryUsersDto): Promise<import("../common/interfaces/api-response.interface").PaginatedResult<unknown>>;
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
