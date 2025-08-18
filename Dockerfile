# ==========================
# Stage 1: Build da aplicação Flutter Web
# ==========================
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Define diretório de trabalho
WORKDIR /app

# Copia configs primeiro (melhor uso do cache)
COPY pubspec.* ./
RUN flutter pub get

# Copia o restante da aplicação
COPY . .

# Build Flutter Web em modo release
RUN flutter build web --release

# ==========================
# Stage 2: Servindo com Nginx
# ==========================
FROM nginx:alpine

# Remove página default do Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copia os arquivos compilados do Flutter para o Nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# Expor a porta padrão
EXPOSE 80

# Iniciar o Nginx
CMD ["nginx", "-g", "daemon off;"]
