export declare class CreateProductDto {
    name: string;
    sku: string;
    barcode?: string;
    description?: string;
    price: number;
    cost?: number;
    stock?: number;
    lowStockThreshold?: number;
    categoryId?: number;
    isActive?: boolean;
}
