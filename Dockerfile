# Step 1: Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json lerna.json ./
COPY packages ./packages

# Install dependencies and bootstrap Lerna
RUN npm install
RUN npx lerna bootstrap

# Build all packages
RUN npx lerna run build

# Step 2: Production stage
FROM node:20-alpine

WORKDIR /app

# Copy built files from builder
COPY --from=builder /app /app

# Environment variables (set via Northflank later)
ENV NODE_ENV=production
ENV PORT=3000

# Expose the port
EXPOSE 3000

# Start Vendure backend
CMD ["node", "packages/server/dist/index.js"]
