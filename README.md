# DockerFile

Create a Dockerfile for WordPress using a multi-stage build,here we will use alpine as the base image to keep it lightweight:

## .env file

```bash
AWS_ACCOUNT_ID=
AWS_REGION=
ECR_WP_REPO_NAME=
ECR_WP_TAG=
ECR_MYSQL_REPO_NAME=
ECR_MYSQL_TAG=

MYSQL_ROOT_PASSWORD=
MYSQL_DATABASE=
MYSQL_USER=
MYSQL_DB_PASSWORD=
WORDPRESS_DB_PASSWORD=
WORDPRESS_TABLE_PREFIX=
```

## Dockerfile.mysql

```# Use the official MySQL image as the base
FROM mysql:8.0

# Expose the default MySQL port
EXPOSE 3306

# Use the default MySQL entrypoint to initialize the DB
CMD ["mysqld"]
`
```

## Dockerfile.wordpress

```# Stage 1: Build WordPress with Alpine Linux
FROM alpine:3.18 AS builder

# Install necessary packages
RUN apk add --no-cache \
    curl \
    tar

# Download WordPress
WORKDIR /wordpress
RUN curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz \
    && tar -xzf wordpress.tar.gz --strip-components=1 \
    && rm wordpress.tar.gz

# Stage 2: Create final image
FROM php:8.2-apache AS final

# Install required PHP extensions
RUN docker-php-ext-install mysqli pdo pdo_mysql && docker-php-ext-enable mysqli

# Enable necessary Apache modules
RUN a2enmod rewrite

# Add non-root user
RUN groupadd -r myuser && useradd -r -g myuser myuser

# Copy WordPress from the builder stage
COPY --from=builder /wordpress /var/www/html

# Set permissions
RUN chown -R myuser:myuser /var/www/html

# Switch to the non-root user
USER myuser

# Expose port 80
EXPOSE 80

CMD ["apache2-foreground"]
```

## docker-compose.yml

#### Now, let's create a docker-compose.yml file that will define the WordPress and MySQL services:

```
version: '3.8'

services:
  db:
    image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_MYSQL_REPO_NAME}:${ECR_MYSQL_TAG}
    container_name: wordpress_db
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD} 
      MYSQL_DATABASE: ${MYSQL_DATABASE}          
      MYSQL_USER: ${MYSQL_USER}                  
      MYSQL_PASSWORD: ${MYSQL_DB_PASSWORD}       
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - wordpress_network

  wordpress:
    image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_WP_REPO_NAME}:${ECR_WP_TAG}
    container_name: wordpress_app
    depends_on:
      - db
    restart: always
    ports:
      - "8080:80" # Expose WordPress on port 8080
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${WORDPRESS_DB_PASSWORD}
      WORDPRESS_TABLE_PREFIX: ${WORDPRESS_TABLE_PREFIX}
    volumes:
      - wordpress_data:/var/www/html/wp-content
    networks:
      - wordpress_network

volumes:
  db_data:
  wordpress_data:

networks:
  wordpress_network:
    driver: bridge
    name: wordpress_brdnetwork
```
