#!/bin/bash

# Solicitar el nombre de dominio
echo "Ingrese el nombre de su dominio (sin www):"
read DOMAIN

# Definir directorio base
BASE_DIR="/root/$DOMAIN"

# Crear el directorio del dominio
mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

# Repositorios
BACKEND_REPO="https://github.com/SolBank24/Api-Solbank.git"
FRONTEND_REPO="https://github.com/SolBank24/Front-Solbank.git"

# Clonar los repositorios
echo "Clonando el backend..."
git clone "$BACKEND_REPO"
echo "Clonando el frontend..."
git clone "$FRONTEND_REPO"

# Definir nombres de carpetas
BACKEND_DIR="$BASE_DIR/Api-Solbank"
FRONTEND_DIR="$BASE_DIR/Front-Solbank"

# Configurar Backend
echo "Configurando el backend..."
cd "$BACKEND_DIR"
cp .env.example .env
composer install
php artisan key:generate

# Configurar Frontend
echo "Configurando el frontend..."
cd "$FRONTEND_DIR"
npm install
npm run build

# Crear red de Docker
echo "Creando red Docker..."
docker network create solbanknet || echo "La red ya existe."

# Configurar Nginx
echo "Configurando Nginx..."
mkdir -p "$BASE_DIR/nginx"
cat > "$BASE_DIR/nginx/nginx.conf" <<EOL
server {
    listen 80;
    server_name $DOMAIN;
    root /var/www/html/public;
    index index.php index.html;
    location / {
        try_files \$uri /index.php?\$query_string;
    }
    location ~ \\.php$ {
        include fastcgi_params;
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOL

# Preguntar si instalar SSL
echo "¿Desea instalar un certificado SSL gratuito con Let's Encrypt? (s/n)"
read INSTALL_SSL
if [ "$INSTALL_SSL" == "s" ]; then
    echo "Instalando Certbot y configurando SSL..."
    apt update && apt install -y certbot python3-certbot-nginx
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m admin@$DOMAIN
fi

# Generar archivo de credenciales
echo "Generando credenciales..."
DB_PASS=$(openssl rand -base64 12)
ADMIN_EMAIL="admin@example.com"
ADMIN_PASS="password"
echo "Base de datos: solbankdb" > "$BASE_DIR/credenciales.txt"
echo "Usuario DB: root" >> "$BASE_DIR/credenciales.txt"
echo "Contraseña DB: $DB_PASS" >> "$BASE_DIR/credenciales.txt"
echo "Correo admin: $ADMIN_EMAIL" >> "$BASE_DIR/credenciales.txt"
echo "Contraseña admin: $ADMIN_PASS" >> "$BASE_DIR/credenciales.txt"

# Mostrar mensaje final
echo "Configuración completada. Sus credenciales están en $BASE_DIR/credenciales.txt"
