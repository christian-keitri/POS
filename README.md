# POS (Point of Sale)

A Flutter point-of-sale app with a Node.js API and SQLite backend. Supports products, categories, orders, and user accounts.

## Quick start (development)

1. **Backend**
   ```bash
   cd server
   cp .env.example .env   # optional: set PORT, etc.
   npm install
   npm run init-db
   npm run dev
   ```
   API runs at `http://localhost:3000` (or your `PORT`).

2. **Flutter app**
   ```bash
   flutter pub get
   flutter run
   ```
   Set the API URL in `lib/config/api_config.dart` if needed (default: `http://127.0.0.1:3000`). On a physical device, use your machine’s IP instead of `127.0.0.1`.

## Production

### Backend (Node.js API)

- **Environment**
  - Copy `server/.env.example` to `server/.env` (or set env vars in the process).
  - Set `NODE_ENV=production`.
  - Set `CORS_ORIGIN` to your app’s origin(s), comma-separated (e.g. `https://your-app.com`). If unset, all origins are allowed.
  - Optional: `PORT`, `DB_PATH`.

- **Run**
  ```bash
  cd server
  npm ci --omit=dev
  NODE_ENV=production npm run start:prod
  ```
  Or run `node index.js` with `NODE_ENV`, `PORT`, `CORS_ORIGIN`, and optionally `DB_PATH` set in the environment.

- **Docker**
  ```bash
  cd server
  docker build -t pos-api .
  docker run -p 3000:3000 -e NODE_ENV=production -e CORS_ORIGIN=https://your-app.com -v pos-data:/app/data -v pos-uploads:/app/uploads pos-api
  ```
  Use volumes for `data` and `uploads` so the database and uploaded images persist.

### Flutter app

- **API URL**
  - Set the production API base URL at build time:
  ```bash
  flutter build apk --dart-define=API_BASE_URL=https://api.your-domain.com
  flutter build ios --dart-define=API_BASE_URL=https://api.your-domain.com
  flutter build web --dart-define=API_BASE_URL=https://api.your-domain.com
  ```
  Do not add a trailing slash. If `API_BASE_URL` is not set, it defaults to `http://127.0.0.1:3000`.

- **Build**
  ```bash
  flutter pub get
  flutter build apk   # or build ios / build web
  ```

## Project structure

- `lib/` – Flutter app (screens, services, config, theme).
- `server/` – Express API, SQLite DB, uploads, and scripts (`init-db`, etc.).
- `server/.env` – Local config (not committed); see `server/.env.example`.

## API overview

- `GET /api/health` – Health check.
- `GET/POST/PUT/DELETE /api/categories` – Categories.
- `GET/POST/PUT/DELETE /api/products` – Products (including image upload at `POST /api/products/:id/image`).
- `GET/POST/PATCH /api/orders` – Orders (and stats, by id).
- `POST /api/auth/signup`, `POST /api/auth/login`, `GET /api/auth/users` – Auth and user list.

See `server/README.md` for full API details.
