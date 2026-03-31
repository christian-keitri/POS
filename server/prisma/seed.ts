import { PrismaClient, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  // ─── Admin user ───────────────────────────────────────────────────
  const adminPassword = await bcrypt.hash('admin123', 12);
  const admin = await prisma.user.upsert({
    where: { email: 'admin@pos.local' },
    update: {},
    create: {
      email: 'admin@pos.local',
      passwordHash: adminPassword,
      displayName: 'Admin',
      businessName: 'POS Store',
      role: Role.ADMIN,
    },
  });
  console.log(`  Admin user: ${admin.email}`);

  // ─── Cashier user ────────────────────────────────────────────────
  const cashierPassword = await bcrypt.hash('cashier123', 12);
  const cashier = await prisma.user.upsert({
    where: { email: 'cashier@pos.local' },
    update: {},
    create: {
      email: 'cashier@pos.local',
      passwordHash: cashierPassword,
      displayName: 'Cashier 1',
      businessName: 'POS Store',
      role: Role.CASHIER,
    },
  });
  console.log(`  Cashier user: ${cashier.email}`);

  // ─── Categories ──────────────────────────────────────────────────
  const categories = ['Beverages', 'Snacks', 'Dairy', 'Bakery'];
  const categoryRecords = [];
  for (let i = 0; i < categories.length; i++) {
    const cat = await prisma.category.upsert({
      where: { name: categories[i] },
      update: {},
      create: { name: categories[i], sortOrder: i },
    });
    categoryRecords.push(cat);
  }
  console.log(`  Categories: ${categories.join(', ')}`);

  // ─── Products ────────────────────────────────────────────────────
  const products = [
    { name: 'Coffee', sku: 'BEV-001', price: 3.50, cost: 1.20, stock: 100, category: 0 },
    { name: 'Green Tea', sku: 'BEV-002', price: 2.50, cost: 0.80, stock: 80, category: 0 },
    { name: 'Potato Chips', sku: 'SNK-001', price: 1.99, cost: 0.70, stock: 150, category: 1 },
    { name: 'Whole Milk 1L', sku: 'DRY-001', price: 2.99, cost: 1.50, stock: 50, category: 2 },
    { name: 'Bottled Water', sku: 'BEV-003', price: 0.99, cost: 0.20, stock: 200, category: 0 },
    { name: 'Croissant', sku: 'BKR-001', price: 2.49, cost: 0.90, stock: 30, category: 3 },
    { name: 'Orange Juice', sku: 'BEV-004', price: 3.99, cost: 1.60, stock: 60, category: 0 },
    { name: 'Chocolate Bar', sku: 'SNK-002', price: 1.49, cost: 0.50, stock: 120, category: 1 },
  ];

  for (const p of products) {
    await prisma.product.upsert({
      where: { sku: p.sku },
      update: {},
      create: {
        name: p.name,
        sku: p.sku,
        price: p.price,
        cost: p.cost,
        stock: p.stock,
        categoryId: categoryRecords[p.category].id,
      },
    });
  }
  console.log(`  Products: ${products.length} seeded`);

  console.log('Seed complete.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
