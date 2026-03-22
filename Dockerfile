FROM node:20-alpine AS builder

WORKDIR /app

# Install docsify-cli
RUN npm install -g docsify-cli@latest

# Copy docs content
COPY . /app/docs

# Generate static site
RUN docsify init /app/docs --theme bare --no-plugin

# Production stage
FROM nginx:alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Copy built docs
COPY --from=builder /app/docs /usr/share/nginx/html

# Copy nginx config for SPA routing
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
    } \
    location /404.html { \
        internal; \
    } \
    location = /health { \
        access_log off; \
        return 200 "OK"; \
        add_header Content-Type text/plain; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
