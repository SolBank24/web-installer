#!/bin/bash

echo "🚀 Iniciando instalación de SolBank..."

# 1️⃣ Solicitar el dominio
read -p "🌍 Ingresa el dominio (ejemplo: midominio.com): " DOMAIN

# 2️⃣ Solicitar el Token de GitHub
read -s -p "🔑 Ingresa tu GitHub Personal Access Token (PAT): " GITHUB_TOKEN
echo "" # Salto de línea

# 3️⃣ Crear directorio con el nombre del dominio
INSTALL_DIR="/root/$DOMAIN"
mkdir -p "$INSTALL_DIR"

echo "📂 Creando directorio en $INSTALL_DIR"
cd "$INSTALL_DIR"

# 4️⃣ Clonar los repositorios privados con autenticación
echo "🔄 Clonando el backend (Api-Solbank)..."
git clone https://$GITHUB_TOKEN@github.com/SolBank24/Api-Solbank.git

echo "🔄 Clonando el frontend (Front-Solbank)..."
git clone https://$GITHUB_TOKEN@github.com/SolBank24/Front-Solbank.git

# 5️⃣ Verificar si se clonaron correctamente
if [ -d "Api-Solbank" ] && [ -d "Front-Solbank" ]; then
    echo "✅ Repositorios clonados exitosamente"
else
    echo "❌ Error al clonar los repositorios, revisa el token o los permisos."
    exit 1
fi

# 6️⃣ Crear la red de Docker
echo "🌐 Creando la red Docker solbanknet..."
docker network create solbanknet || echo "⚠️ La red ya existe, continuando..."

# 7️⃣ Configuración de Backend (Laravel)
echo "⚙️ Configurando Backend (Laravel)..."
cd Api-Solbank
cp .env.example .env
docker run --rm -v $(pwd):/app -w /app laravelsail/php82-composer:latest composer install
cd ..

# 8️⃣ Configuración de Frontend (Vue 3)
echo "⚙️ Configurando Frontend (Vue 3)..."
cd Front-Solbank
docker run --rm -v $(pwd):/app -w /app node:18-alpine npm install
cd ..

# 9️⃣ Preguntar si desea instalar SSL con Let's Encrypt
read -p "🔒 ¿Deseas instalar un certificado SSL gratuito con Let's Encrypt? (s/n): " INSTALL_SSL
if [[ "$INSTALL_SSL" == "s" || "$INSTALL_SSL" == "S" ]]; then
    echo "🔧 Configurando SSL con Certbot..."
    apt update && apt install -y certbot python3-certbot-nginx
    certbot --nginx -d "$DOMAIN"
    echo "✅ Certificado SSL instalado correctamente."
else
    echo "⚠️ Saltando instalación de SSL."
fi

# 🔟 Crear archivo con credenciales importantes
echo "📝 Guardando credenciales en credenciales.txt..."
DB_PASSWORD=$(openssl rand -hex 12)
echo "Dominio: $DOMAIN" > credenciales.txt
echo "Base de Datos: solbankdb" >> credenciales.txt
echo "Usuario BD: root" >> credenciales.txt
echo "Password BD: $DB_PASSWORD" >> credenciales.txt
echo "Email admin: admin@solbank.com" >> credenciales.txt
echo "Contraseña admin: admin1234" >> credenciales.txt
echo "⚠️ Guarda este archivo en un lugar seguro."

echo "🎉 Instalación completada. ¡Bienvenido a SolBank!"
