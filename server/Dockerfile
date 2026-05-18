# Build stage
FROM public.ecr.aws/docker/library/node:20-alpine AS build


WORKDIR /app

# Install dependencies for Prisma/bcrypt if needed
# RUN apk add --no-cache python3 make g++ 

COPY package.json package-lock.json ./

RUN npm ci

COPY . .

# Build the NestJS application
RUN npm run build

# Prune dev dependencies
RUN npm ci --omit=dev && npm cache clean --force

# Production stage
FROM public.ecr.aws/docker/library/node:20-alpine AS production


# Create a non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy necessary files from build stage
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json

# If using Prisma, copy the generated client
# COPY --from=build /app/prisma ./prisma

# Set correct ownership
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 3000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

CMD ["node", "dist/main.js"]
