ARG PHP_BASE_IMAGE=scratch

FROM $PHP_BASE_IMAGE

LABEL maintainer="Yannick Vanhaeren"

SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ARG PHP_VERSION
ARG NODE_VERSION

COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN curl --silent --show-error --location  https://get.docker.com | bash

RUN curl --silent --show-error --location "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" | \
    tar --extract --xz --directory /usr/local --strip-components=1 --no-same-owner && \
    cd /usr/local/bin && ln --symbolic node nodejs && \
    npm install --global yarn

RUN apt update && apt install --assume-yes --no-install-recommends \
        git \
        less \
        vim \
        unzip \
        php$PHP_VERSION-xdebug && \
    apt clean && \
    rm --recursive /var/lib/apt/lists/*

RUN sed --in-place "s|account default : transmeat|account default : mailhog|" /etc/msmtprc && \
    ini_path=/etc/php/${PHP_VERSION}/mods-available && \
    echo "opcache.revalidate_freq=0" >> $ini_path/opcache.ini && \
    sed --in-place "s|opcache.validate_timestamps=0|opcache.validate_timestamps=1|" $ini_path/opcache.ini && \
    sed --in-place "s|zend_extension|;zend_extension|" $ini_path/xdebug.ini && \
    echo "xdebug.default_enable=1" >> $ini_path/xdebug.ini && \
    echo "xdebug.profiler_enable=0" >> $ini_path/xdebug.ini && \
    echo "xdebug.idekey=PHPSTORM" >> $ini_path/xdebug.ini && \
    echo "xdebug.max_nesting_level=200" >> $ini_path/xdebug.ini && \
    echo "xdebug.remote_enable=1" >> $ini_path/xdebug.ini && \
    echo "xdebug.remote_autostart=0" >> $ini_path/xdebug.ini
