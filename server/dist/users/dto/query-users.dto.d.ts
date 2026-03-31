import { Role } from '@prisma/client';
import { PaginationDto } from '../../common/dto/pagination.dto';
export declare class QueryUsersDto extends PaginationDto {
    role?: Role;
    isActive?: boolean;
}
