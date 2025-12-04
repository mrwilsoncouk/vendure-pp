# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies for building native modules
RUN apk add --no-cache python3 make g++ bash git

# Copy root files
COPY package.json package-lock.json lerna.json ./

# Install root dependencies
RUN npm install

# Copy packages
COPY packages ./packages

# Install dependencies in all packages
RUN npx lerna exec -- npm install

# Build all packages
RUN npx lerna run build

# Stage 2: Production
FROM node:20-alpine

WORKDIR /app

# Install minimal dependencies
RUN apk add --no-cache bash

# Copy built app from builder
COPY --from=builder /app /app

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["node", "packages/server/dist/index.js"]
