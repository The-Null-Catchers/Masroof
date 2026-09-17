# syntax=docker/dockerfile:1
# Masroof API runtime image (PHP-FPM). Used by docker-compose and CI.
FROM docker.io/library/php:8.5-fpm-alpine AS base

RUN apk add --no-cache icu-libs libpq libzip postgresql-client freetype libpng libjpeg-turbo libwebp \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS icu-dev libpq-dev libzip-dev linux-headers freetype-dev libpng-dev libjpeg-turbo-dev libwebp-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j"$(nproc)" pdo_pgsql intl bcmath pcntl zip gd \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del .build-deps \
    && rm -rf /tmp/pear

COPY --from=docker.io/library/composer:2 /usr/bin/composer /usr/bin/composer
COPY docker/php/conf.d/masroof.ini /usr/local/etc/php/conf.d/masroof.ini

WORKDIR /var/www/backend

# ---------- Development image: source is bind-mounted ----------
FROM base AS dev
ENV APP_ENV=local

# ---------- Production image: source and optimized vendor baked in ----------
FROM base AS prod
ENV APP_ENV=production
COPY docker/php/conf.d/opcache-prod.ini /usr/local/etc/php/conf.d/opcache-prod.ini
COPY backend/composer.json backend/composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction
COPY backend/ ./
RUN composer dump-autoload --optimize --classmap-authoritative --no-dev \
    && chown -R www-data:www-data storage bootstrap/cache
USER www-data
