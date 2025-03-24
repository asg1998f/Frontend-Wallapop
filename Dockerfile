# Etapa 1: Construir la aplicación Flutter
FROM ubuntu:20.04 AS build-env

# Establecer variables de entorno para evitar interacciones durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependencias necesarias
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && apt-get clean

# Descargar e instalar Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Habilitar soporte para web y verificar la instalación
RUN flutter doctor -v
RUN flutter config --enable-web

# Copiar el proyecto al contenedor
RUN mkdir /app
COPY . /app
WORKDIR /app

# Obtener dependencias y construir la aplicación web
RUN flutter pub get
RUN flutter build web --release

# Etapa 2: Servir la aplicación con Nginx
FROM nginx:1.21.1-alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Exponer el puerto 80 para acceder a la aplicación
EXPOSE 80