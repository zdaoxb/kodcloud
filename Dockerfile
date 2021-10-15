FROM php:7.3-apache

LABEL MAINTAINER="dhso <dhso@163.com>"

RUN a2enmod rewrite

ENV KODCOLUD_VERSION 1.23
ENV KODCOLUD_URL http://static.kodcloud.com/update/download/kodbox.${KODCOLUD_VERSION}.zip

RUN set -ex; \
    \
    apk update && apk upgrade &&\
    apk add --no-cache \
        rsync \
	supervisor \
	imagemagick \
	ffmpeg \
	tzdata \
	unzip \
	
	# forward request and error logs to docker log collector

	  && mkdir -p /var/log/supervisor && \
	cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
	echo "Asia/Shanghai" > /etc/timezone

RUN set -x \
  && mkdir -p /usr/src/kodcloud \
  && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget unzip && rm -rf /var/lib/apt/lists/* \
  && wget -q -O /tmp/kodcloud.zip ${KODCOLUD_URL} \
  && unzip -q /tmp/kodcloud.zip -d /usr/src/kodcloud/ \
  && apt-get purge -y --auto-remove ca-certificates wget \
  && rm -rf /var/cache/apk/* \
  && rm -rf /tmp/*

RUN set -ex; \
    \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        autoconf \
        freetype-dev \
        icu-dev \
        libevent-dev \
        libjpeg-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libmemcached-dev \
        libxml2-dev \
        libzip-dev \
        openldap-dev \
        pcre-dev \
        libwebp-dev \
        gmp-dev \
    ; \
    \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-configure intl; \
    docker-php-ext-configure ldap; \
    docker-php-ext-install -j "$(nproc)" \
        bcmath \
        exif \
        gd \
        intl \
        ldap \
        opcache \
        pcntl \
        pdo_mysql \
	mysqli \
        zip \
        gmp \
    ; \
    \
# pecl will claim success even if one install fails, so we need to perform each install separately
    pecl install memcached; \
    pecl install redis; \
    pecl install mcrypt; \
    \
    docker-php-ext-enable \
        memcached \
        redis \
        mcrypt \
    ; \
    



  && rm -rf /var/cache/apk/*

WORKDIR /var/www/html

COPY docker-apache2.conf /etc/apache2/conf-enabled/
COPY docker-php.ini /usr/local/etc/php/conf.d/
COPY entrypoint.sh /usr/local/bin/
RUN chmod a+x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]
