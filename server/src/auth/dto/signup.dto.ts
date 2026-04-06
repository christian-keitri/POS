import { IsEmail, IsString, MinLength, IsOptional, IsEnum } from 'class-validator';
import { Transform } from 'class-transformer';
import { Role } from '@prisma/client';

export class SignupDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsOptional()
  @IsString()
  businessName?: string;

  @IsOptional()
  @IsString()
  displayName?: string;

  @IsOptional()
  @Transform(({ value }) => {
    if (!value) return value;
    return typeof value === 'string' ? value.toUpperCase() : value;
  })
  @IsEnum(Role)
  role?: Role;
}
