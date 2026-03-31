import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable, map } from 'rxjs';
import { ApiResponse } from '../interfaces/api-response.interface';

@Injectable()
export class ResponseInterceptor<T> implements NestInterceptor<T, ApiResponse<T>> {
  intercept(
    _context: ExecutionContext,
    next: CallHandler<T>,
  ): Observable<ApiResponse<T>> {
    return next.handle().pipe(
      map((result) => {
        // If the service returned { data, meta }, spread them into the standard format
        if (result && typeof result === 'object' && 'meta' in result && 'data' in result) {
          const paginated = result as Record<string, unknown>;
          return {
            success: true,
            data: paginated.data as T,
            meta: paginated.meta as ApiResponse<T>['meta'],
          };
        }
        return { success: true, data: result };
      }),
    );
  }
}
