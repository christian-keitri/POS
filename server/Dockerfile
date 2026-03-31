FROM node:20-alpine AS builder
WORKDIR /app

RUN apk add --no-cache openssl

COPY package.json package-lock.json* ./
RUN npm ci

COPY prisma ./prisma
RUN npx prisma generate

COPY tsconfig.json tsconfig.build.json nest-cli.json ./
COPY src ./src
RUN npm run build

# ---
FROM node:20-alpine
WORKDIR /app

RUN apk add --no-cache openssl

RUN addgroup -S app && adduser -S app -G app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/prisma ./prisma
COPY package.json ./

RUN mkdir -p uploads && chown -R app:app /app
USER app

EXPOSE 3000
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/main"]
