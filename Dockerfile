# Composer Build
FROM composer:1.9.3 as vendor
WORKDIR /tmp/
COPY composer.json composer.json
COPY composer.lock composer.lock

RUN composer install \
    --ignore-platform-reqs \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist



# Install packages and remove default server definition
FROM alpine:3.16.0 as app
RUN apk update
RUN apk add --no-cache zip unzip curl sqlite nginx supervisor bash

#Install php8
RUN apk add --no-cache php8 \
    php8-common \
    php8-fpm \
    php8-pdo \
    php8-opcache \
    php8-zip \
    php8-phar \
    php8-iconv \
    php8-cli \
    php8-curl \
    php8-openssl \
    php8-mbstring \
    php8-tokenizer \
    php8-fileinfo \
    php8-json \
    php8-xml \
    php8-xmlwriter \
    php8-simplexml \
    php8-dom \
    php8-pdo_mysql \
    php8-pdo_sqlite \
    php8-tokenizer \
    php8-pecl-redis \
    php8-redis

# Installing composer
#RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
#RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
#RUN rm -rf composer-setup.php

# Configure supervisor
RUN mkdir -p /etc/supervisor.d/
COPY ./config/supervisord.ini /etc/supervisor.d/supervisord.ini

# Configure PHP
RUN mkdir -p /run/php/
RUN touch /run/php/php8.0-fpm.pid
COPY ./config/php.ini-prod /etc/php8/php.ini
COPY ./config/php-fpm.conf /etc/php8/php-fpm.conf

# Setup document root
RUN mkdir -p /usr/share/nginx/html
WORKDIR /usr/share/nginx/html

# Configure nginx
COPY ./config/nginx.conf /etc/nginx/
RUN mkdir -p /run/nginx/
RUN touch /run/nginx/nginx.pid
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

# Copy build
COPY . /usr/share/nginx/html
COPY --from=vendor /tmp/vendor/ /usr/share/nginx/html/vendor
RUN chown -R nobody:nobody /usr/share/nginx/html
RUN chmod -R 755 /usr/share/nginx/html
EXPOSE 80
CMD ["supervisord", "-c", "/etc/supervisor.d/supervisord.ini"]
