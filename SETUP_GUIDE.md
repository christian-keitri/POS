# POS System - Quick Start Guide

## Prerequisites

- **Node.js** v18 or higher
- **npm** or **yarn**
- **Flutter** SDK v3.0 or higher
- **iOS Simulator** or **Android Emulator** (for mobile development)
- **Chrome** or **Edge** (for web development)

## Backend Setup

### 1. Install Dependencies

```bash
cd server
npm install
```

### 2. Create Environment File

Create a `.env` file in the `server` directory:

```env
NODE_ENV=development
PORT=3000
DB_PATH=./data/pos.db
CORS_ORIGIN=http://localhost:*
```

### 3. Initialize Database

```bash
npm run init-db
```

This command will:
- Create the SQLite database file
- Set up all tables with proper schema
- Add indexes for performance
- Seed sample data (categories and products)

### 4. Start the Server

```bash
# Development mode with auto-reload
npm run dev

# Or production mode
npm start
```

The API will be available at `http://localhost:3000`

### 5. Test the API

```bash
# Health check
curl http://localhost:3000/api/health

# Get products
curl http://localhost:3000/api/products

# Get categories
curl http://localhost:3000/api/categories
```

## Frontend Setup

### 1. Install Flutter Dependencies

```bash
# From the project root
flutter pub get
```

### 2. Run on Your Platform

#### iOS (macOS only)
```bash
flutter run -d ios
```

#### Android
```bash
flutter run -d android
```

#### Web
```bash
flutter run -d chrome
```

#### macOS Desktop
```bash
flutter run -d macos
```

### 3. Default Login

On first launch, create an account using the signup screen. The first user created will be an admin.

Or you can manually create a test user:

```bash
cd server
node -e "
const  db = require('./db');
const bcrypt = require('bcryptjs');
db.prepare('INSERT INTO users (email, password_hash, business_name, display_name, role) VALUES (?, ?, ?, ?, ?)').run(
  'admin@example.com',
  bcrypt.hashSync('admin123', 10),
  'Demo Store',
  'Admin User',
  'admin'
);
console.log('Test admin user created: admin@example.com / admin123');
"
```

## Project Structure

```
pos/
├── server/                 # Backend API
│   ├── data/              # SQLite database
│   ├── lib/               # Utilities
│   ├── routes/            # API route handlers
│   ├── scripts/           # Database scripts
│   ├── uploads/           # Product images
│   ├── db.js             # Database connection
│   └── index.js          # Express app entry
│
├── lib/                   # Flutter frontend
│   ├── config/           # Configuration
│   ├── Core/             # Core widgets (AppBar, Nav)
│   ├── models/           # Data models
│   ├── screens.dart/     # UI screens
│   ├── services/         # API services
│   ├── theme/            # App theming
│   ├── widgets/          # Reusable widgets
│   └── main.dart         # App entry point
│
└── DEVELOPMENT_GUIDE.md  # Detailed documentation
```

## API Documentation

### Authentication Endpoints

#### Signup
```http
POST /api/auth/signup
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "business_name": "My Store",
  "display_name": "John Doe"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

### Product Endpoints

#### List Products
```http
GET /api/products?category_id=1&active_only=1
```

#### Create Product
```http
POST /api/products
Content-Type: application/json

{
  "name": "Coffee",
  "sku": "SKU-001",
  "barcode": "123456789",
  "price": 3.50,
  "cost": 1.50,
  "stock": 100,
  "category_id": 1,
  "low_stock_threshold": 20
}
```

### Order Endpoints

#### Create Order
```http
POST /api/orders
Content-Type: application/json

{
  "cashier_id": 1,
  "payment_method": "cash",
  "tax_rate": 10,
  "items": [
    {
      "product_id": 1,
      "quantity": 2
    }
  ]
}
```

#### Get Receipt
```http
GET /api/orders/1/receipt
```

### Stock Management

#### Get Low Stock Alerts
```http
GET /api/stock/alerts
```

#### Adjust Stock
```http
POST /api/stock/adjust
Content-Type: application/json

{
  "product_id": 1,
  "user_id": 1,
  "quantity_change": 50,
  "reason": "purchase",
  "notes": "Restocking from supplier"
}
```

### Reports

#### Sales Report
```http
GET /api/reports/sales?period=daily
GET /api/reports/sales?start_date=2026-03-01&end_date=2026-03-05
```

#### Inventory Report
```http
GET /api/reports/inventory?category_id=1
```

#### Top Products
```http
GET /api/reports/top-products?period=monthly&limit=10
```

## Common Issues

### Backend won't start
- Check if port 3000 is already in use: `lsof -i :3000`
- Make sure `data/` directory exists
- Run `npm run init-db` if database doesn't exist

### Flutter build errors
- Run `flutter clean && flutter pub get`
- Check Flutter version: `flutter --version`
- Upgrade Flutter if needed: `flutter upgrade`

### Connection refused from Flutter app
- Make sure backend is running on `http://localhost:3000`
- For iOS simulator, use `http://localhost:3000`
- For Android emulator, use `http://10.0.2.2:3000`
- Update `lib/config/api_config.dart` if needed

### SQLite errors
- Delete `server/data/pos.db` and run `npm run init-db` again
- Make sure the `data/` directory has write permissions

## Development Workflow

### 1. Start Backend Server
```bash
cd server
npm run dev  # Auto-reloads on code changes
```

### 2. Start Flutter App
```bash
# In another terminal
flutter run
```

### 3. Make Changes
- Backend: Edit files in `server/routes/` or `server/lib/`
- Frontend: Edit files in `lib/`

### 4. Hot Reload (Flutter)
- Press `r` in the terminal to hot reload
- Press `R` for hot restart
- Press `q` to quit

### 5. View Logs
- Backend: Check terminal where `npm run dev` is running
- Frontend: Check terminal where `flutter run` is running

## Production Deployment

### Backend

**Option 1: Docker**
```bash
cd server
docker build -t pos-api .
docker run -p 3000:3000 -v $(pwd)/data:/app/data pos-api
```

**Option 2: PM2 (Process Manager)**
```bash
npm install -g pm2
cd server
pm2 start index.js --name pos-api
pm2 save
pm2 startup
```

### Frontend

**Web**
```bash
flutter build web
# Deploy the build/web/ directory to your hosting provider
```

**Mobile**
```bash
# iOS (requires Mac with Xcode)
flutter build ios --release

# Android
flutter build apk --release
flutter build appbundle --release
```

**Desktop**
```bash
# macOS
flutter build macos --release

# Windows (on Windows machine)
flutter build windows --release

# Linux (on Linux machine)
flutter build linux --release
```

## Next Steps

1. Review [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md) for detailed architecture
2. Explore the API endpoints using Postman or curl
3. Customize the theme in `lib/theme/app_theme.dart`
4. Add your business logo and branding
5. Configure payment gateway integration
6. Set up barcode scanner integration
7. Add receipt printer support

## Support

For issues or questions:
1. Check the [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md)
2. Review the code comments
3. Check Flutter and Node.js documentation

## License

This project is provided as-is for commercial or educational use.
