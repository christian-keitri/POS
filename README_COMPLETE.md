# 🏪 Complete POS System - Production Ready

A comprehensive Point of Sale (POS) system built with **Flutter** (frontend) and **Node.js + Express + SQLite** (backend). This system is designed for retail stores, restaurants, and small to medium businesses.

## ✨ Features

### 🔐 User Management
- **Role-Based Access Control** (Admin, Manager, Cashier)
- User authentication with encrypted passwords
- User activity logging and audit trails
- Account management (create, edit, deactivate users)

### 📦 Product & Inventory Management
- Complete CRUD operations for products
- Category management with sorting
- Product image uploads (JPEG, PNG, GIF, WebP)
- Barcode support
- Real-time stock tracking
- Low stock threshold alerts
- Stock adjustment logs with reasons (purchase, damage, return, manual adjustment)

### 💰 Sales Module
- Create and process sales orders
- Multiple payment methods (Cash, Card, Digital Wallet, Mixed)
- Order management (pending, completed, cancelled, refunded)
- Tax and discount support
- Order-level and item-level discounts
- Unique order numbers
- Receipt generation
- Order history and search

### 📊 Reports & Analytics
- **Sales Reports**: Daily, weekly, monthly breakdowns
- **Revenue Analytics**: Trends and totals
- **Inventory Reports**: Stock value, profit margins
- **Top Products**: Best sellers by quantity and revenue
- **Payment Method Analysis**: Breakdown by payment type
- **Cashier Performance**: Sales metrics per user
- **User Activity Logs**: Complete audit trail

### 🎨 UI/UX
- Modern, clean Material Design
- Responsive layout (mobile, tablet, desktop)
- Dark mode support (via theme)
- Loading states and error handling
- Success/error notifications

## 🛠️ Tech Stack

### Backend
- **Node.js** v18+ with Express.js
- **SQLite** database (via better-sqlite3)
- **bcryptjs** for password hashing
- **multer** for file uploads
- **cors** for cross-origin support

### Frontend
- **Flutter** v3.x (cross-platform)
- **Dart** programming language
- **http** package for REST API calls
- Works on: iOS, Android, Web, macOS, Windows, Linux

### Database
- **SQLite** embedded database
- Foreign key constraints
- Indexed for performance
- Transaction support

## 📋 Prerequisites

- Node.js v18 or higher
- npm or yarn
- Flutter SDK v3.0 or higher
- iOS Simulator, Android Emulator, or Chrome (for development)

## 🚀 Quick Start

### 1. Backend Setup

```bash
# Navigate to server directory
cd server

# Copy environment file
cp .env.example .env

# Install dependencies
npm install

# Initialize database with sample data
npm run init-db

# Start development server
npm run dev
```

The API will be running at `http://localhost:3000`

### 2. Frontend Setup

```bash
# From project root
flutter pub get

# Run on your platform
flutter run -d chrome        # Web
flutter run -d ios          # iOS
flutter run -d android      # Android
flutter run -d macos        # macOS Desktop
```

### 3. Create Admin Account

On first launch, use the signup screen to create an admin account. Alternatively, create one via terminal:

```bash
cd server
node -e "
const db = require('./db');
const bcrypt = require('bcryptjs');
db.prepare('INSERT INTO users (email, password_hash, business_name, display_name, role) VALUES (?, ?, ?, ?, ?)').run(
  'admin@pos.com',
  bcrypt.hashSync('admin123', 10),
  'My Business',
  'Admin User',
  'admin'
);
console.log('Admin created: admin@pos.com / admin123');
"
```

## 📁 Project Structure

```
pos/
├── lib/                           # Flutter app
│   ├── Core/                     # Core widgets
│   │   ├── app_state.dart       # Global app state
│   │   ├── custom_app_bar.dart  # Reusable app bar
│   │   └── custom_bottom_nav.dart
│   ├── config/
│   │   └── api_config.dart      # API base URL config
│   ├── models/                   # Data models
│   │   ├── category.dart
│   │   ├── order.dart
│   │   ├── product.dart
│   │   ├── user.dart
│   │   ├── stock_adjustment.dart
│   │   └── reports.dart
│   ├── screens.dart/             # UI screens
│   │   ├── cart_screen.dart
│   │   ├── home_screen.dart
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   ├── order_detail_screen.dart
│   │   └── product_form_screen.dart
│   ├── services/
│   │   └── api_service.dart     # Complete API client
│   ├── theme/
│   │   └── app_theme.dart       # App theming
│   ├── widgets/
│   │   └── category_pills.dart  # Reusable widgets
│   └── main.dart                 # App entry point
│
├── server/                        # Backend API
│   ├── data/                     # SQLite database
│   ├── lib/                      # Utilities
│   │   ├── auth.js              # Auth middleware
│   │   └── safeError.js         # Error handling
│   ├── routes/                   # API routes
│   │   ├── auth.js              # User management
│   │   ├── categories.js        # Category CRUD
│   │   ├── orders.js            # Order management
│   │   ├── products.js          # Product CRUD
│   │   ├── stock.js             # Stock management
│   │   └── reports.js           # Analytics
│   ├── scripts/
│   │   └── init-db.js           # Database setup
│   ├── uploads/                  # Product images
│   ├── .env.example             # Environment template
│   ├── db.js                     # Database connection
│   ├── index.js                  # Express app
│   └── package.json
│
├── DEVELOPMENT_GUIDE.md          # Detailed documentation
├── SETUP_GUIDE.md                # Setup instructions
└── README.md                     # This file
```

## 🔌 API Endpoints Summary

### Authentication
- `POST /api/auth/signup` - Create account
- `POST /api/auth/login` - User login
- `GET /api/auth/users` - List users
- `GET /api/auth/users/:id` - Get user
- `POST /api/auth/users` - Create user
- `PUT /api/auth/users/:id` - Update user
- `DELETE /api/auth/users/:id` - Deactivate user

### Products
- `GET /api/products` - List products
- `GET /api/products/:id` - Get product
- `POST /api/products` - Create product
- `PUT /api/products/:id` - Update product
- `DELETE /api/products/:id` - Delete product
- `POST /api/products/:id/image` - Upload image

### Categories
- `GET /api/categories` - List categories
- `POST /api/categories` - Create category
- `PUT /api/categories/:id` - Update category
- `DELETE /api/categories/:id` - Delete category

### Orders
- `GET /api/orders` - List orders
- `GET /api/orders/:id` - Get order with items
- `POST /api/orders` - Create order
- `PATCH /api/orders/:id` - Update order
- `GET /api/orders/stats` - Order statistics
- `GET /api/orders/:id/receipt` - Receipt data

### Stock Management
- `GET /api/stock/adjustments` - Stock adjustment history
- `POST /api/stock/adjust` - Manual stock adjustment
- `GET /api/stock/alerts` - Low stock alerts

### Reports
- `GET /api/reports/sales` - Sales reports
- `GET /api/reports/inventory` - Inventory reports
- `GET /api/reports/top-products` - Best sellers
- `GET /api/reports/user-activity` - Activity logs
- `GET /api/reports/revenue` - Revenue analytics
- `GET /api/reports/cashier-performance` - Cashier metrics

## 🎯 User Roles & Permissions

### Admin
✅ Full system access  
✅ User management  
✅ Product & category management  
✅ Process sales  
✅ View all reports  
✅ Stock adjustments  
✅ System configuration  

### Manager
✅ Product & category management  
✅ Process sales  
✅ View reports  
✅ Stock adjustments  
✅ Manage cashiers  
❌ Cannot manage admins/managers  

### Cashier
✅ Process sales  
✅ View products  
✅ View own sales  
❌ Cannot manage products  
❌ Cannot view financial reports  
❌ Cannot adjust stock  

## 📱 Platform Support

- ✅ **iOS**: iPhone & iPad
- ✅ **Android**: Phones & Tablets
- ✅ **Web**: Chrome, Safari, Firefox, Edge
- ✅ **macOS**: Desktop app
- ✅ **Windows**: Desktop app (with Flutter 3.x)
- ✅ **Linux**: Desktop app (with Flutter 3.x)

## 🔧 Development

### Backend Development
```bash
cd server
npm run dev  # Auto-reload on file changes
```

### Frontend Development
```bash
# Hot reload enabled by default
flutter run

# Press 'r' to hot reload
# Press 'R' to hot restart
# Press 'q' to quit
```

### Database Management
```bash
# Reset database
cd server
rm data/pos.db
npm run init-db

# Clear orders only
npm run clear-orders
```

## 🚢 Production Deployment

### Backend

**Docker Deployment:**
```bash
cd server
docker build -t pos-api .
docker run -p 3000:3000 -v $(pwd)/data:/app/data pos-api
```

**PM2 Deployment:**
```bash
npm install -g pm2
cd server
pm2 start index.js --name pos-api
pm2 save
pm2 startup
```

### Frontend

**Web:**
```bash
flutter build web
# Deploy build/web/ to hosting (Netlify, Vercel, etc.)
```

**Mobile:**
```bash
# iOS (requires macOS + Xcode)
flutter build ios --release

# Android
flutter build apk --release
flutter build appbundle --release
```

**Desktop:**
```bash
# macOS
flutter build macos --release

# Windows (on Windows)
flutter build windows --release

# Linux (on Linux)
flutter build linux --release
```

## 🔒 Security Features

- ✅ Password hashing with bcrypt (10 rounds)
- ✅ SQL injection prevention (prepared statements)
- ✅ Input validation on all endpoints
- ✅ Role-based access control
- ✅ File upload validation
- ✅ CORS configuration
- ✅ User activity logging
- ✅ Secure password requirements (min 8 characters)

## 🎨 Customization

### Change API URL
Edit `lib/config/api_config.dart`:
```dart
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://your-api-url.com',
);
```

### Change Theme
Edit `lib/theme/app_theme.dart` to customize colors, fonts, and styling.

### Add Business Logo
Replace images in `assets/images/` and update references in the code.

## 📚 Documentation

- [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md) - Comprehensive development guide
- [SETUP_GUIDE.md](./SETUP_GUIDE.md) - Detailed setup instructions
- API Documentation - See inline code comments

## 🐛 Troubleshooting

### Backend won't start
```bash
# Check if port 3000 is in use
lsof -i :3000

# Make sure database directory exists
mkdir -p server/data
cd server && npm run init-db
```

### Flutter build errors
```bash
flutter clean
flutter pub get
flutter doctor  # Check for any issues
```

### Connection errors from app
- iOS/Web: Use `http://localhost:3000`
- Android Emulator: Use `http://10.0.2.2:3000`
- Update `lib/config/api_config.dart` accordingly

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is available for commercial and educational use.

## 💡 Future Enhancements

- [ ] Barcode scanner integration
- [ ] Receipt printer support
- [ ] Payment gateway integration
- [ ] Multi-currency support
- [ ] Customer management
- [ ] Loyalty program
- [ ] Email receipts
- [ ] SMS notifications
- [ ] Offline mode with sync
- [ ] Data export (CSV, PDF)
- [ ] Advanced analytics with charts
- [ ] Multi-location support
- [ ] Employee scheduling
- [ ] Supplier management

## 📞 Support

For questions, issues, or feature requests:
1. Check the documentation (DEVELOPMENT_GUIDE.md, SETUP_GUIDE.md)
2. Review the code comments
3. Check Flutter and Node.js official documentation

---

**Built with ❤️ using Flutter & Node.js**
