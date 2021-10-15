	FROM php:7.3-apache

LABEL MAINTAINER="dhso <dhso@163.com>"

RUN a2enmod rewrite

ENV KODCOLUD_VERSION 1.23
ENV KODCOLUD_URL http://static.kodcloud.com/update/download/kodbox.${KODCOLUD_VERSION}.zip

RUN set -x \
  && mkdir -p /usr/src/kodcloud \
  && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget unzip && rm -rf /var/lib/apt/lists/* \
  && wget -q -O /tmp/kodcloud.zip ${KODCOLUD_URL} \
  && unzip -q /tmp/kodcloud.zip -d /usr/src/kodcloud/ \
  && apt-get purge -y --auto-remove ca-certificates wget \
  && rm -rf /var/cache/apk/* \
  && rm -rf /tmp/*

RUN set -x \
  && apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        exiftool \
  && docker-php-ext-install -j$(nproc) iconv \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install -j$(nproc) gd \
  && docker-php-ext-install exif \
  && docker-php-ext-configure exif --enable-exif \
  && rm -rf /var/cache/apk/*

WORKDIR /var/www/html

COPY docker-apache2.conf /etc/apache2/conf-enabled/
COPY docker-php.ini /usr/local/etc/php/conf.d/
COPY entrypoint.sh /usr/local/bin/
RUN chmod a+x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]
