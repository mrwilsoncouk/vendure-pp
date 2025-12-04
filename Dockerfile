# Use official Node.js LTS image
FROM node:20-bullseye AS builder

# Set working directory
WORKDIR /app

# Copy package files first for caching
COPY package*.json ./
COPY lerna.json ./

# Copy all packages
COPY packages ./packages

# Clean old node_modules (optional, safer in monorepo)
RUN rm -rf node_modules \
    && npx lerna exec -- rm -rf node_modules || true

# Clean npm cache to prevent corrupted tarballs
RUN npm cache clean --force

# Install dependencies in all packages safely
RUN npx lerna exec -- npm install --force --legacy-peer-deps

# Bootstrap monorepo packages
RUN npx lerna bootstrap --ci --force-local

# Copy the rest of the project
COPY . .

# Build your packages (if required)
RUN npx lerna run build

# Production image
FROM node:20-bullseye-slim

WORKDIR /app

# Copy node_modules and built code from builder
COPY --from=builder /app /app

# Expose your app port
EXPOSE 3000

# Start your app (adjust to your start command)
CMD ["npm", "run", "start:prod"]
