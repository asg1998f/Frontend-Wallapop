# Etapa 1: Compilar la aplicación Flutter para web
FROM cirrusci/flutter:3.24.3 AS build
WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --release

# Etapa 2: Servir la aplicación con Nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]