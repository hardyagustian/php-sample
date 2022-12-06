ARG ALPINE_VERSION=3.16.0
FROM alpine:${ALPINE_VERSION}
LABEL Description="Technical Test Eka"
# Setup document root
WORKDIR /var/www/html

# Install packages and remove default server definition
RUN apk update
RUN apk add --no-cache zip unzip curl sqlite nginx supervisor


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
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN rm -rf composer-setup.php

# Configure supervisor
RUN mkdir -p /etc/supervisor.d/
COPY ./config/supervisord.ini /etc/supervisor.d/supervisord.ini

# Configure PHP
RUN mkdir -p /run/php/
RUN touch /run/php/php8.0-fpm.pid
COPY ./config/php.ini-prod /etc/php8/php.ini
COPY ./config/php-fpm.conf /etc/php8/php-fpm.conf


# Configure nginx
COPY ./config/nginx.conf /etc/nginx/

RUN mkdir -p /run/nginx/
RUN touch /run/nginx/nginx.pid

RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log



# Building process
COPY ./config/composer.json /var/www/html/
RUN composer install --no-dev
RUN chown -R nobody:nobody /var/www/html/

EXPOSE 80
CMD ["supervisord", "-c", "/etc/supervisor.d/supervisord.ini"]
