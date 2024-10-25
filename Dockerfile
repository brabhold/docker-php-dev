ARG PHP_BASE_IMAGE=scratch

FROM $PHP_BASE_IMAGE

ARG PHP_BASE_IMAGE
ARG NODE_VERSION

LABEL maintainer="Yannick Vanhaeren"

ARG DEBIAN_FRONTEND=noninteractive

COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN set -e; \
    curl --silent --show-error --location "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" | \
    tar --extract --xz --directory /usr/local --strip-components=1 --no-same-owner; \
    cd /usr/local/bin && ln --symbolic node nodejs; \
    npm install -g yarn

RUN set -e; \
    apt-get update && apt-get install -y --no-install-recommends \
        git \
        less \
        vim \
        unzip; \
    apt-get clean; \
    rm -r /var/lib/apt/lists/*;

RUN set -e; \
    curl --silent --show-error --location  https://get.docker.com | bash

RUN set -e; \
    if echo $PHP_BASE_IMAGE | grep -q "7.4"; then pecl install xdebug-3.1.6; else pecl install xdebug; fi; \
    docker-php-ext-enable xdebug; \
    pecl clear-cache

RUN set -e; \
    docker-php-source extract; \
    cp /usr/src/php/php.ini-development /usr/local/etc/php/php.ini; \
    cd /usr/local/etc/php; \
    sed -i -e "s|post_max_size = 8M|post_max_size = 55M|" php.ini; \
    sed -i -e "s|memory_limit = 128M|memory_limit = 1024M|" php.ini; \
    sed -i -e "s|;max_input_vars = 1000|max_input_vars = 3000|" php.ini; \
    sed -i -e "s|upload_max_filesize = 2M|upload_max_filesize = 50M|" php.ini; \
    sed -i -e "s|;sendmail_path =|sendmail_path = /usr/bin/msmtp -t|" /usr/local/etc/php/php.ini; \
    sed -i -e "s|max_execution_time = 30|max_execution_time = 60|" php.ini; \
    sed -i -e "s|;date.timezone =|date.timezone = Europe/Brussels|" php.ini; \
    sed -i -e "s|;cgi.fix_pathinfo=1|cgi.fix_pathinfo = 0|" php.ini; \
    sed -i -e "s|;realpath_cache_size = 4096k|realpath_cache_size = 4096K|" php.ini; \
    sed -i -e "s|;realpath_cache_ttl = 120|realpath_cache_ttl = 600|" php.ini; \
    docker-php-source delete

RUN set -e; \
    sed -i -e "s|account default : transmeat|account default : mailhog|" /etc/msmtprc

RUN set -e; \
    cd /usr/local/etc/php/conf.d; \
    echo "opcache.revalidate_freq=0" >> docker-php-ext-opcache.ini; \
    sed -i -e "s|opcache.validate_timestamps=0|opcache.validate_timestamps=1|" docker-php-ext-opcache.ini

RUN set -e; \
    cd /usr/local/etc/php/conf.d; \
    sed -i -e "s|zend_extension|;zend_extension|" docker-php-ext-xdebug.ini; \
    echo "xdebug.default_enable=1" >> docker-php-ext-xdebug.ini; \
    echo "xdebug.profiler_enable=0" >> docker-php-ext-xdebug.ini; \
    echo "xdebug.idekey=PHPSTORM" >> docker-php-ext-xdebug.ini; \
    echo "xdebug.max_nesting_level=200" >> docker-php-ext-xdebug.ini; \
    echo "xdebug.remote_enable=1" >> docker-php-ext-xdebug.ini; \
    echo "xdebug.remote_autostart=0" >> docker-php-ext-xdebug.ini
