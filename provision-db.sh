#debes completar este archivo con los comandos necesarios para provisionar la base de datos
#!/bin/bash

echo "Actualizando paquetes e instalando PostgreSQL..."
# Actualiza la lista de paquetes
apt-get update -y
# Instala el servidor PostgreSQL y utilidades
apt-get install -y postgresql postgresql-contrib

# Cambia 'listen_addresses' de 'localhost' a '*' (todas las interfaces)
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/12/main/postgresql.conf

# Permite conexiones desde la red 192.168.56.0/24 (donde está la máquina 'web') usando contraseña (md5)
echo "host    all             all             192.168.56.0/24            md5" | sudo tee -a /etc/postgresql/12/main/pg_hba.conf > /dev/null

# Reiniciar PostgreSQL para aplicar cambios de red
sudo systemctl restart postgresql

echo "Creando usuario, base de datos y datos de ejemplo..."

# Ejecutar comandos de PostgreSQL como el usuario 'postgres'
sudo -u postgres psql << EOF
-- 2.1 Crea un usuario para la aplicación web
CREATE USER appuser WITH PASSWORD 'apppassword';
-- 2.2 Crea la base de datos para el taller
CREATE DATABASE tallerdb OWNER appuser;
-- 2.3 Se conecta a la base de datos
\c tallerdb
-- 2.4 Crea la tabla 'usuarios'
CREATE TABLE usuarios (
    id serial PRIMARY KEY,
    nombre VARCHAR ( 50 ) UNIQUE NOT NULL,
    rol VARCHAR ( 50 ) NOT NULL
);
-- 2.5 Inserta datos de ejemplo
INSERT INTO usuarios (nombre, rol) VALUES ('Federico de la Cruz', 'Aguatero') ON CONFLICT (nombre) DO NOTHING;
INSERT INTO usuarios (nombre, rol) VALUES ('Caracoles Gutierrez', 'Waterista') ON CONFLICT (nombre) DO NOTHING;
INSERT INTO usuarios (nombre, rol) VALUES ('Gatuber Suaq', 'Industrial');
INSERT INTO usuarios (nombre, rol) VALUES ('Velcema', 'Empresarial');
INSERT INTO usuarios (nombre, rol) VALUES ('Ñerosquiz', 'Panamerica');
-- 2.6 Otorga permisos al usuario de la aplicación
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO appuser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO appuser;
EOF

echo "Provisionamiento de DB completado."
