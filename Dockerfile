# Builder stage
FROM ghcr.io/cirruslabs/flutter:latest AS builder

ARG BUILD_NAME
ARG BUILD_NUMBER

# Set the working directory
WORKDIR /app

# Copy the source code to the container
COPY . /app

# Get dependencies and build the web application
RUN flutter pub get
RUN flutter packages pub run build_runner build --delete-conflicting-outputs
RUN flutter build web --build-name $BUILD_NAME --build-number $BUILD_NUMBER

# Runner stage
FROM nginx:alpine

# Copy the built app from the builder stage to the nginx server
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy the nginx configuration file
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Set environment variables (replace these with the actual values or pass them at runtime)
ENV API_BASE_URL="http://192.168.2.110:8001"
ENV LOG_LEVEL="INFO"

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
