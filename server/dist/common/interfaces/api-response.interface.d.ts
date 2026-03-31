export interface ApiResponse<T = unknown> {
    success: boolean;
    data: T;
    error?: string;
    meta?: PaginationMeta;
}
export interface PaginationMeta {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
}
export interface PaginatedResult<T> {
    data: T[];
    meta: PaginationMeta;
}
