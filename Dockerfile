# Use official Node LTS image
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Install build tools for native dependencies
RUN apk add --no-cache python3 g++ make bash git

# Copy only package files first for better caching
COPY package.json package-lock.json ./
COPY packages/*/package.json ./packages/

# Clean npm cache and remove node_modules (safety)
RUN rm -rf node_modules && npm cache clean --force

# Install dependencies safely
RUN npm ci

# Bootstrap Lerna workspaces
RUN npx lerna bootstrap --hoist

# Copy the rest of the source code
COPY . .

# Build the project
RUN npm run build

# Production image
FROM node:20-alpine AS production

WORKDIR /app

# Copy only needed files from builder
COPY --from=builder /app/package.json /app/package-lock.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/dist ./dist

# Expose default Vendure port
EXPOSE 3000

# Default command
CMD ["node", "dist/apps/server/main.js"]
