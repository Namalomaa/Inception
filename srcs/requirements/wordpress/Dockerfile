FROM	debian:12.15

RUN	apt-get update && apt-get install -y \
	php8.2-fpm \
	php8.2-cli \
	php8.2-mysql \
	php8.2-curl \
	php8.2-gd \
	php8.2-mbstring \
	php8.2-xml \
	php8.2-zip \
	curl \
	wget \
	&& rm -rf /var/lib/apt/list/*

WORKDIR	/var/www/html

RUN	wget https://wordpress.org/wordpress-7.1.tar.gz \
	&& tar -xzf wordpress-7.1.tar.gz --strip-components=1 \
	&& rm wordpress-7.1.tar.gz

RUN	curl -o /usr/local/bin/wp \
	https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /usr/local/bin/wp

COPY	conf/www.conf	/etc/php/8.2/fpm/pool.d/ww.conf
COPY	tools/wordpress.sh /wordpress.sh

RUN	chmod +x /wordpress.sh

EXPOSE	9000

ENTRYPOINT	["/wordpress.sh"]
