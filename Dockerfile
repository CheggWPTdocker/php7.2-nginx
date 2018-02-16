FROM php:7.2-fpm-alpine3.7
LABEL maintainer="Joel Gilley jgilley@chegg.com"

ENV TIMEZONE=UTC \
	ENV=/etc/profile \
	APP_ENV=development

RUN apk --update add dumb-init ca-certificates nginx supervisor bash && \
	apk add --virtual .build_package git curl build-base autoconf dpkg-dev \
		file libmagic re2c && \
	apk add --virtual .deps_run libxpm freetype xextproto inputproto xtrans \
		libwebp libxext libxt libx11 libxcb libxau libsm libice libxdmcp \
		libbsd xproto libuuid kbproto libpthread-stubs libpng tidyhtml-libs \
		tidyhtml libmemcached-libs zlib freetds unixodbc readline libpq \
		 gettext-asprintf gettext-libs libintl gettext libunistring libldap zlib \
		icu-libs libmemcached cyrus-sasl libmcrypt hiredis gmp && \
	apk add --virtual .build_deps libxau-dev libbsd-dev libxdmcp-dev libxcb-dev \
		libx11-dev libxext-dev libice-dev libsm-dev libxt-dev libxpm-dev libpng-dev \
		freetype-dev libjpeg-turbo-dev libwebp-dev bzip2-dev gettext-dev gmp-dev \
		icu-dev freetds-dev postgresql-dev libxml2-dev tidyhtml-dev zlib-dev \
		libmemcached-dev cyrus-sasl-dev libmcrypt-dev hiredis-dev tzdata

RUN cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
	echo "${TIMEZONE}" > /etc/timezone && \
	update-ca-certificates && \
	rm -rf /etc/nginx/conf.d/default.conf && \
	mv /etc/profile.d/color_prompt /etc/profile.d/color_prompt.sh && \
	echo alias dir=\'ls -alh --color\' >> /etc/profile && \
	echo 'source ~/.profile' >> /etc/profile && \
	mkdir -p /app /run/nginx && \
	chown -R nginx:www-data /run/nginx && \
	chown -R :www-data /app && \
	chmod -R g+rw /app

RUN docker-php-ext-install -j$(nproc) bcmath bz2 gd gettext gmp intl mysqli \
	pdo_dblib pdo_mysql pdo_pgsql soap tidy xmlrpc opcache zip

# pecl installs for apcu memcached and mcrypt
RUN pecl install apcu && \
	pecl install memcached && \
	pecl install mcrypt channel://pecl.php.net/mcrypt-1.0.1

# Install phpiredis
RUN git clone https://github.com/nrk/phpiredis.git && \
	cd phpiredis && \
	phpize && ./configure --enable-phpiredis && \
	make && make install

# Tideways ENVs
ENV tideways_version=1.5.3 \
	tideways_ext_version=4.1.5 \
	tideways_php_version=2.0.16 \
	tideways_dl=https://github.com/tideways/

# Install tideways module
RUN cd /tmp && \
	curl -L "${tideways_dl}/php-profiler-extension/archive/v${tideways_ext_version}.zip" \
	--output "/tmp/v${tideways_ext_version}.zip" && \
	cd /tmp && unzip "v${tideways_ext_version}.zip" && \
	cd "php-xhprof-extension-${tideways_ext_version}" && \
	phpize && \
	./configure && \
	make && make install

# install tideways profiler
RUN curl -L "${tideways_dl}/profiler/releases/download/v${tideways_php_version}/Tideways.php" \
	--output "$(php-config --extension-dir)/Tideways.php" && \
	ls -l "$(php-config --extension-dir)/Tideways.php" && \
	cd /tmp && rm -rf php-xhprof-extension-${tideways_ext_version}/ v${tideways_ext_version}.zip

# install tideways daemon
RUN cd /tmp && \
	wget https://s3-eu-west-1.amazonaws.com/tideways/daemon/${tideways_version}/tideways-daemon-v${tideways_version}-alpine.tar.gz && \
	tar -zxf tideways-daemon-v${tideways_version}-alpine.tar.gz && \
	mv build/dist/tideways-daemon /usr/bin && \
	ls -l /usr/bin/tideways-daemon && \
	mkdir -p /var/run/tideways && \
	cd /tmp && rm -rf build/ tideways-daemon-v${tideways_version}-alpine.tar.gz

# enable the above
RUN docker-php-ext-enable apcu memcached mcrypt phpiredis tideways

# install nginx
RUN apk del .build_deps && \
	apk del .build_package

RUN php -m && \
	php -v