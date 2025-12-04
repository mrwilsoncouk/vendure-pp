# Stage 1: Build the app
FROM node:20-alpine AS builder
WORKDIR /app

# Copy main package files
COPY package.json package-lock.json lerna.json ./

# Install root dependencies
RUN npm install

# Copy all packages
COPY packages ./packages

# Install dependencies in all packages
RUN npx lerna exec -- npm install

# Build all packages
RUN npx lerna run build

# Stage 2: Production image
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app /app
ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000
CMD ["node", "packages/server/dist/index.js"]
