# Production Dockerfile for POS API server
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Production dependencies only
RUN npm ci --omit=dev

# Copy application
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S pos && adduser -u 1001 -S pos -G pos \
  && mkdir -p data uploads && chown -R pos:pos /app/data /app/uploads

USER pos

EXPOSE 3000

ENV NODE_ENV=production
ENV PORT=3000

# Initialize DB if missing, then start server
CMD ["sh", "-c", "node scripts/init-db.js && node index.js"]
