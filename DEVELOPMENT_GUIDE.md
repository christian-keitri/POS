# POS System - Complete Development Guide

## 🏗️ Tech Stack

### Backend
- **Node.js** (v18+) with Express.js
- **SQLite** via better-sqlite3 (embedded database)
- **bcryptjs** for password hashing
- **multer** for file uploads
- **cors** for cross-origin requests
- **morgan** for request logging

### Frontend
- **Flutter** (v3.x) - cross-platform UI framework
- **Dart** programming language
- **http** package for REST API calls
- **shared_preferences** for offline storage

### Database
- **SQLite** - embedded relational database
- Foreign key constraints enabled
- Transaction support for data integrity

## 📊 Database Schema

### Tables Overview

#### users
Stores user accounts with role-based access control.
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  business_name TEXT,
  display_name TEXT,
  role TEXT DEFAULT 'cashier' CHECK (role IN ('admin', 'manager', 'cashier')),
  is_active INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);
```

**Roles:**
- `admin`: Full access to all features
- `manager`: Can manage products, view reports, manage cashiers
- `cashier`: Can process sales, view products

#### categories
Product categories for organization.
```sql
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);
```

#### products
Product catalog with inventory tracking.
```sql
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  sku TEXT UNIQUE,
  barcode TEXT,
  description TEXT,
  price REAL NOT NULL CHECK (price >= 0),
  cost REAL DEFAULT 0 CHECK (cost >= 0),
  stock INTEGER DEFAULT 0 CHECK (stock >= 0),
  low_stock_threshold INTEGER DEFAULT 10,
  category_id INTEGER REFERENCES categories(id),
  image_path TEXT,
  is_active INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);
```

#### orders
Sales transactions.
```sql
CREATE TABLE orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_number TEXT UNIQUE,
  user_id INTEGER REFERENCES users(id),
  cashier_id INTEGER REFERENCES users(id),
  total REAL NOT NULL DEFAULT 0,
  subtotal REAL NOT NULL DEFAULT 0,
  tax_amount REAL DEFAULT 0,
  discount_amount REAL DEFAULT 0,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'cancelled', 'refunded')),
  payment_method TEXT CHECK (payment_method IN ('cash', 'card', 'digital_wallet', 'mixed')),
  payment_details TEXT,
  notes TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);
```

#### order_items
Line items for each order.
```sql
CREATE TABLE order_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id INTEGER NOT NULL REFERENCES products(id),
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price REAL NOT NULL,
  subtotal REAL NOT NULL,
  discount_amount REAL DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now'))
);
```

#### stock_adjustments
Track all inventory changes.
```sql
CREATE TABLE stock_adjustments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL REFERENCES products(id),
  user_id INTEGER REFERENCES users(id),
  quantity_change INTEGER NOT NULL,
  old_stock INTEGER NOT NULL,
  new_stock INTEGER NOT NULL,
  reason TEXT CHECK (reason IN ('sale', 'purchase', 'adjustment', 'damage', 'return')),
  notes TEXT,
  reference_type TEXT,
  reference_id INTEGER,
  created_at TEXT DEFAULT (datetime('now'))
);
```

#### user_activity_logs
Audit trail for user actions.
```sql
CREATE TABLE user_activity_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER REFERENCES users(id),
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id INTEGER,
  details TEXT,
  ip_address TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);
```

## 🔌 API Endpoints

### Authentication
- `POST /api/auth/signup` - Create new account
- `POST /api/auth/login` - Authenticate user
- `GET /api/auth/users` - List all users (admin only)
- `PUT /api/auth/users/:id` - Update user (admin only)
- `DELETE /api/auth/users/:id` - Deactivate user (admin only)

### Products
- `GET /api/products` - List products (with filters)
- `GET /api/products/:id` - Get single product
- `POST /api/products` - Create product
- `PUT /api/products/:id` - Update product
- `DELETE /api/products/:id` - Delete product
- `POST /api/products/:id/image` - Upload product image
- `GET /api/products/low-stock` - Get low stock alerts

### Categories
- `GET /api/categories` - List categories
- `POST /api/categories` - Create category
- `PUT /api/categories/:id` - Update category
- `DELETE /api/categories/:id` - Delete category

### Orders
- `GET /api/orders` - List orders
- `GET /api/orders/:id` - Get order details
- `POST /api/orders` - Create order
- `PATCH /api/orders/:id` - Update order status
- `DELETE /api/orders/:id` - Cancel order
- `GET /api/orders/stats` - Get order statistics
- `GET /api/orders/:id/receipt` - Generate receipt

### Stock Management
- `GET /api/stock/adjustments` - List stock adjustments
- `POST /api/stock/adjust` - Adjust stock manually
- `GET /api/stock/alerts` - Get low stock alerts

### Reports
- `GET /api/reports/sales` - Sales reports (daily/weekly/monthly)
- `GET /api/reports/inventory` - Inventory reports
- `GET /api/reports/user-activity` - User activity logs
- `GET /api/reports/top-products` - Best selling products
- `GET /api/reports/revenue` - Revenue analytics

## 🚀 Setup Instructions

### Backend Setup

1. **Install Dependencies**
```bash
cd server
npm install
```

2. **Environment Configuration**
Create `.env` file in server directory:
```env
NODE_ENV=development
PORT=3000
DB_PATH=./data/pos.db
CORS_ORIGIN=http://localhost:*
```

3. **Initialize Database**
```bash
npm run init-db
```

4. **Start Server**
```bash
# Development with auto-reload
npm run dev

# Production
npm start
```

### Frontend Setup

1. **Install Flutter Dependencies**
```bash
flutter pub get
```

2. **Run on Device/Emulator**
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Web
flutter run -d chrome

# Desktop
flutter run -d macos
```

3. **Build for Production**
```bash
# iOS
flutter build ios

# Android
flutter build apk

# Web
flutter build web

# Desktop
flutter build macos
```

## 🔐 Security Best Practices

1. **Password Security**
   - Minimum 8 characters
   - Hashed with bcrypt (10 rounds)
   - Never stored in plain text

2. **Role-Based Access Control**
   - Middleware checks user role for protected endpoints
   - Frontend hides unauthorized features

3. **SQL Injection Prevention**
   - Prepared statements for all queries
   - Input validation and sanitization

4. **File Upload Security**
   - File type validation (images only)
   - File size limits (5MB)
   - Secure file naming

5. **Environment Variables**
   - Sensitive config in .env file
   - Never commit .env to version control

## 📱 Features by Role

### Admin
- ✅ Full system access
- ✅ User management (create, edit, delete)
- ✅ Product & category management
- ✅ Process sales
- ✅ View all reports & analytics
- ✅ Stock adjustments
- ✅ System configuration

### Manager
- ✅ Product & category management
- ✅ Process sales
- ✅ View reports & analytics
- ✅ Stock adjustments
- ✅ Manage cashiers
- ❌ Cannot manage admins or other managers

### Cashier
- ✅ Process sales
- ✅ View products
- ✅ View own sales history
- ❌ Cannot manage products
- ❌ Cannot view financial reports
- ❌ Cannot adjust stock

## 🎨 UI/UX Guidelines

1. **Responsive Design**
   - Mobile-first approach
   - Tablet optimization
   - Desktop layout for back-office

2. **Accessibility**
   - High contrast colors
   - Large touch targets
   - Clear labels and feedback

3. **Performance**
   - Lazy loading for lists
   - Image optimization
   - Offline-first architecture

4. **User Feedback**
   - Loading indicators
   - Success/error messages
   - Confirmation dialogs for destructive actions

## 📊 Offline Capability

### Strategy
1. **Local Storage**
   - Use `shared_preferences` for app settings
   - SQLite for offline transaction queue

2. **Sync Mechanism**
   - Queue orders when offline
   - Auto-sync when connection restored
   - Conflict resolution

3. **Data Caching**
   - Cache product catalog
   - Cache category list
   - Periodic refresh when online

## 🔄 Development Roadmap

### Phase 1: Core Foundation ✅
- [x] Database schema design
- [x] Basic authentication
- [x] Product CRUD
- [x] Category management
- [x] Order creation

### Phase 2: Enhanced Features (Current)
- [ ] Role-based access control
- [ ] Stock adjustment logs
- [ ] Multiple payment methods
- [ ] Receipt generation
- [ ] Low stock alerts

### Phase 3: Analytics & Reports
- [ ] Sales reports
- [ ] Inventory reports
- [ ] User activity logs
- [ ] Dashboard with charts
- [ ] Export to CSV/PDF

### Phase 4: Advanced Features
- [ ] Offline mode with sync
- [ ] Barcode scanner integration
- [ ] Receipt printer integration
- [ ] Payment gateway integration
- [ ] Multi-currency support

### Phase 5: Optimization
- [ ] Performance optimization
- [ ] UI/UX improvements
- [ ] Automated testing
- [ ] Documentation
- [ ] Deployment guides

## 🧪 Testing

### Backend Testing
```bash
# Run tests (to be implemented)
npm test
```

### Frontend Testing
```bash
# Run tests
flutter test

# Integration tests
flutter test integration_test
```

## 📦 Deployment

### Backend Deployment Options
1. **VPS/Cloud VM** (DigitalOcean, AWS EC2)
2. **Platform-as-a-Service** (Heroku, Railway)
3. **Docker Container** (with Docker Compose)

### Frontend Deployment
1. **Mobile**: App Store & Google Play
2. **Web**: Static hosting (Netlify, Vercel)
3. **Desktop**: Standalone installers

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## 📝 License

This project is for educational/commercial use.

## 💬 Support

For questions or issues, please refer to the documentation or create an issue.
