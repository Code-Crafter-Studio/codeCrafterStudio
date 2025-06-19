# Multi-stage build para optimizar el tamaño de la imagen
FROM node:18-alpine AS base

# Instalar dependencias necesarias
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copiar archivos de configuración de dependencias
COPY package*.json ./
COPY bun.lockb* ./

# Stage para instalar dependencias
FROM base AS deps
RUN npm ci --only=production && npm cache clean --force

# Stage para el build
FROM base AS builder
COPY package*.json ./
COPY bun.lockb* ./
RUN npm ci

# Copiar código fuente
COPY . .

# Build de la aplicación
RUN npm run build

# Stage final - imagen de producción
FROM nginx:alpine AS runner

# Copiar configuración de nginx con SSL
COPY <<EOF /etc/nginx/conf.d/default.conf
# Redirección HTTP a HTTPS
server {
    listen 80;
    server_name codecrafstudio.com www.codecrafstudio.com;
    
    # Ubicación para validación de certificados Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # Redireccionar todo el tráfico HTTP a HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# Configuración HTTPS
server {
    listen 443 ssl http2;
    server_name codecrafstudio.com www.codecrafstudio.com;
    root /usr/share/nginx/html;
    index index.html;

    # Configuración SSL
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    
    # Configuración SSL moderna y segura
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Configuración para SEO y performance
    location / {
        try_files \$uri \$uri/ /index.html;
        
        # Headers de cache para recursos estáticos
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, no-transform";
        }
        
        # Headers de seguridad mejorados para HTTPS
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    }

    # Compresión gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Logs de acceso y errores
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
}
EOF

# Crear directorio para certificados SSL
RUN mkdir -p /etc/nginx/ssl

# Copiar archivos buildados desde el stage builder
COPY --from=builder /app/dist /usr/share/nginx/html

# Exponer puerto 80
EXPOSE 80

# Comando para iniciar nginx
CMD ["nginx", "-g", "daemon off;"] 