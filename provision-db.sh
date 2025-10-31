#!/bin/bash
set -euo pipefail

# Provisionamiento automático de PostgreSQL (parámetros ajustados, funcionalidad intacta)

echo "---- Inicio: actualizando paquetes e instalando PostgreSQL ----"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y postgresql postgresql-contrib

# Detectar versión/dir de postgres instalado (soporta múltiples versiones)
PG_VERSION_DIR="$(ls /etc/postgresql 2>/dev/null | sort -V | tail -n1 || true)"
if [ -z "$PG_VERSION_DIR" ]; then
  echo "No se encontró /etc/postgresql/* — usando ruta por defecto '12'..."
  PG_VERSION_DIR="12"
fi
PG_CONF_DIR="/etc/postgresql/${PG_VERSION_DIR}/main"

echo "Usando configuración de PostgreSQL en: $PG_CONF_DIR"

# 1. Configuración de Acceso Remoto
echo "---- Configurando listen_addresses y pg_hba.conf ----"

# 1.1 Asegurar que 'listen_addresses' esté configurado a '*' (cambia comentario o línea existente)
# Esta expresión sustituye la línea aunque esté comentada o no.
if [ -f "${PG_CONF_DIR}/postgresql.conf" ]; then
  sudo sed -i "s/^#*[[:space:]]*listen_addresses[[:space:]]*=.*/listen_addresses = '*'/" "${PG_CONF_DIR}/postgresql.conf"
else
  echo "Atención: no se encontró postgresql.conf en ${PG_CONF_DIR}. Omitiendo configuración de listen_addresses."
fi

# 1.2 Configura Acceso Remoto (pg_hba.conf)
# Cambié la red permitida a 10.0.2.0/24 (común en entornos de VM) — puedes ajustarla si lo deseas.
PG_HBA_LINE="host    all             all             10.0.2.0/24            md5"
if [ -f "${PG_CONF_DIR}/pg_hba.conf" ]; then
  # No duplicar la línea si ya existe
  if ! grep -Fxq "$PG_HBA_LINE" "${PG_CONF_DIR}/pg_hba.conf"; then
    echo "$PG_HBA_LINE" | sudo tee -a "${PG_CONF_DIR}/pg_hba.conf" > /dev/null
    echo "Línea agregada a pg_hba.conf: $PG_HBA_LINE"
  else
    echo "La línea ya existe en pg_hba.conf — no se añade duplicado."
  fi
else
  echo "Atención: no se encontró pg_hba.conf en ${PG_CONF_DIR}. Omitiendo modificación de pg_hba.conf."
fi

# 1.3 Reiniciar PostgreSQL para aplicar cambios
echo "Reiniciando servicio postgresql..."
sudo systemctl restart postgresql

echo "---- Creando usuario, base de datos y datos de ejemplo (con comprobaciones) ----"

# Parámetros modificados pero funcionales:
APP_USER="webapp"
APP_PASS="webapppass123"
DB_NAME="taller_db"

# 2.1 Crear usuario (si no existe)
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${APP_USER}'" | grep -q 1; then
  echo "Usuario ${APP_USER} ya existe — no se creará de nuevo."
else
  sudo -u postgres psql -c "CREATE ROLE ${APP_USER} WITH LOGIN PASSWORD '${APP_PASS}';"
  echo "Usuario ${APP_USER} creado."
fi

# 2.2 Crear la base de datos (si no existe) con encoding UTF8
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "${DB_NAME}"; then
  echo "Base de datos ${DB_NAME} ya existe — no se creará de nuevo."
else
  sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${APP_USER} ENCODING 'UTF8';"
  echo "Base de datos ${DB_NAME} creada."
fi

# 2.3 Ejecutar el resto de comandos dentro de la base de datos
sudo -u postgres psql -d "${DB_NAME}" <<'EOF'
-- 2.4 Crear tabla 'usuarios' si no existe (con restricción UNIQUE en nombre)
CREATE TABLE IF NOT EXISTS usuarios (
    id serial PRIMARY KEY,
    nombre VARCHAR (50) UNIQUE NOT NULL,
    rol VARCHAR (50) NOT NULL
);

-- 2.5 Insertar datos de ejemplo usando ON CONFLICT DO NOTHING para evitar duplicados
INSERT INTO usuarios (nombre, rol) VALUES ('Federico de la Cruz', 'Aguatero') ON CONFLICT (nombre) DO NOTHING;
INSERT INTO usuarios (nombre, rol) VALUES ('Caracoles Gutierrez', 'Waterista') ON CONFLICT (nombre) DO NOTHING;

-- 2.6 Otorgar permisos al usuario de la aplicación
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO webapp;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO webapp;
EOF

echo "Provisionamiento de Data Base completado correctamente."
