#debes completar este archivo con los comandos necesarios para provisionar la base de datos
#!/usr/bin/env bash
set -euo pipefail

# --- Actualiza los paquetes del sistema ---
sudo apt-get update -y

# --- Instala PostgreSQL ---
sudo apt-get install -y postgresql postgresql-contrib

# --- Inicia y habilita el servicio ---
sudo systemctl enable postgresql
sudo systemctl start postgresql

# --- Crear usuario y base de datos (idempotente) ---
sudo -u postgres psql <<'SQL'
-- Crear usuario si no existe
DO
$$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'vagrant') THEN
      CREATE ROLE vagrant WITH LOGIN PASSWORD 'vagrant';
   END IF;
END
$$;

-- Crear base de datos si no existe y asignar propietario
SELECT 'CREATE DATABASE taller OWNER vagrant' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname='taller')\gexec

-- Crear tabla si no existe y poblarla si está vacía
\c taller
CREATE TABLE IF NOT EXISTS personas (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(50)
);

INSERT INTO personas (nombre)
SELECT v FROM (VALUES ('Samuel'), ('Deyton'), ('Sebastian')) AS t(v)
WHERE NOT EXISTS (SELECT 1 FROM personas);
SQL

echo "Provisionamiento PostgreSQL completado: usuario=vagrant db=taller"
