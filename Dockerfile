FROM alpine:3.11

LABEL MAINTAINER="dhso <dhso@163.com>"

ENV KODCOLUD_VERSION 1.09
ENV KODCOLUD_URL http://static.kodcloud.com/update/download/kodbox.${KODCOLUD_VERSION}.zip

ENV S6RELEASE v1.22.1.0
ENV S6URL     https://github.com/just-containers/s6-overlay/releases/download/
ENV S6_READ_ONLY_ROOT 1

RUN set -x \
  # Install dependencies
  && apk add --no-cache nginx ca-certificates wget unzip gnupg \
  php7-fpm php7-json php7-gd php7-opcache php7-pdo_mysql php7-curl \
  php7-pdo_pgsql tzdata php7-iconv php7-exif \
  && apk upgrade --no-cache\
  && export GNUPGHOME="$(mktemp -d)" \
  && gpg2 --list-public-keys || /bin/true \
  # Remove (some of the) default nginx config
  && rm -f /etc/nginx.conf /etc/nginx/conf.d/default.conf /etc/php7/php-fpm.d/www.conf \
  && rm -rf /etc/nginx/sites-* \
  # Ensure nginx logs, even if the config has errors, are written to stderr
  && ln -s /dev/stderr /var/log/nginx/error.log

RUN set -x \
  # Install Kodcloud
  && mkdir -p /tmp/kodcloud \
  && wget -q -O /tmp/kodcloud.zip ${KODCOLUD_URL} \
  && unzip -q /tmp/kodcloud.zip -d /tmp/kodcloud/ \
  && cp -a /tmp/kodcloud/* /var/www/

RUN set -x \
  # Install s6 overlay for service management
  && wget -qO - https://keybase.io/justcontainers/key.asc | gpg2 --import - \
  && cd /tmp \
  && S6ARCH=$(uname -m) \
  && case ${S6ARCH} in \
  x86_64) S6ARCH=amd64;; \
  armv7l) S6ARCH=armhf;; \
  esac \
  && wget  -q -O /tmp/s6-overlay-${S6ARCH}.tar.gz.sig ${S6URL}${S6RELEASE}/s6-overlay-${S6ARCH}.tar.gz.sig \
  && wget  -q -O /tmp/s6-overlay-${S6ARCH}.tar.gz ${S6URL}${S6RELEASE}/s6-overlay-${S6ARCH}.tar.gz \
  && gpg2 --verify /tmp/s6-overlay-${S6ARCH}.tar.gz.sig \
  && tar -xzf /tmp/s6-overlay-${S6ARCH}.tar.gz -C / \
  # Support running s6 under a non-root user
  && mkdir -p /etc/services.d/nginx/supervise /etc/services.d/php-fpm7/supervise \
  && mkfifo \
  /etc/services.d/nginx/supervise/control \
  /etc/services.d/php-fpm7/supervise/control \
  /etc/s6/services/s6-fdholderd/supervise/control

RUN set -x \
  && adduser nobody www-data \
  && chown -R nobody.www-data /etc/services.d /etc/s6 /run /var/lib/nginx /var/www \
  # && chmod -R 755 /var/www \
  # Clean up
  && rm -rf "${GNUPGHOME}" /tmp/* \
  && apk del gnupg

COPY etc/ /etc/

WORKDIR /var/www
USER nobody:www-data

VOLUME /run /tmp /var/lib/nginx/tmp

EXPOSE 8080

ENTRYPOINT ["/init"]