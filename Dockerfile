# ETAPA 1: builder, instala dependencias de desarrollo
FROM node:18-alpine AS builder
# Alpine Linux reduce el tamaño final.
# Node 18 es estable para producción.
WORKDIR /app
# Copiamos solo los archivos de dependencias primero.
COPY package*.json ./
RUN npm ci --only=production

# ETAPA 2: production, imagen final ligera
FROM node:18-alpine AS production
WORKDIR /app
# Crear usuario no-root antes de copiar archivos.
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
# Copiamos los node_modules ya instalados desde el builder
COPY --from=builder /app/node_modules ./node_modules
# Copiamos el código fuente
COPY server.js ./
COPY package*.json ./
# Cambiamos el propietario de los archivos al usuario no-root
RUN chown -R appuser:appgroup /app
# Cambiamos al usuario no-root
USER appuser
# Documentamos el puerto que usa la aplicación
EXPOSE 3000
# Healthcheck: Docker verifica que el contenedor esté sano
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
CMD wget -qO- http://localhost:3000/api/usuarios || exit 1
# Comando de inicio
CMD ["node", "server.js"]