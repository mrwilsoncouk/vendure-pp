# Use official Node LTS image
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Install build tools for native dependencies
RUN apk add --no-cache python3 g++ make bash git

# Copy only package files first for caching optimization
COPY package.json ./package.json
COPY packages/*/package.json ./packages/
COPY lerna.json ./lerna.json   # <-- explicit path avoids lstat error

# Clean npm cache and remove node_modules (safety)
RUN rm -rf node_modules && npm cache clean --force

# Install dependencies safely, ignoring peer conflicts
RUN npm install --legacy-peer-deps

# If you still need Lerna bootstrap, keep this line.
# Otherwise comment/remove it and rely on npm workspaces.
# RUN npx lerna bootstrap --hoist

# Copy the rest of the source code
COPY . .

# Build the project
RUN npm run build

# ---- Production image ----
FROM node:20-alpine AS production

WORKDIR /app

# Copy only the necessary files from builder
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/lerna.json ./lerna.json   # <-- include if runtime tools expect it

# Expose default Vendure port
EXPOSE 3000

# Default command
CMD ["node", "dist/apps/server/main.js"]
# dummy commit to trigger build
