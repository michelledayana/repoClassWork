FROM postgres:15

# Variables de entorno (credenciales)
ENV POSTGRES_USER=postgresql
ENV POSTGRES_PASSWORD=dayana
ENV POSTGRES_DB=holamundo

# Script de inicialización
COPY init.sql /docker-entrypoint-initdb.d/

# Puerto por defecto de PostgreSQL
EXPOSE 5432
