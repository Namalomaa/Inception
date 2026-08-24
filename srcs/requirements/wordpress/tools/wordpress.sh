#!/bin/bash

set	-e


: "${WP_ADMIN_USER:?WP_ADMIN_USER is not set}"
: "${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL is not set}"
: "${MYSQL_DATABASE:?MYSQL_DATABASE is not set}"
: "${MYSQL_USER:?MYSQL_USER is not set}"
: "${DOMAIN_NAME:?DOMAIN_NAME is not set}"
: "${WP_USER:?WP_USER is not set}"
: "${WP_USER_EMAIL:?WP_USER_EMAIL is not set}"


DB_PASSWORD=$(cat /run/secrets/db_pass)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_pass)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_pass)


mkdir	-p /run/php


if	[ ! -f /var/www/html/wp-config.php ];then
	wp config create \
		--allow-root \
		--path=/var/www/html \
		--dbname="$MYSQL_DATABASE" \
		--dbuser="$MYSQL_USER" \
	 	--dbpass="$DB_PASSWORD" \
	 	--dbhost="mariadb:3306"

fi


if	! wp core is-installed --allow-root --path=/var/www/html; then
	
	wp core install \
		--allow-root \
		--path=/var/www/html \
		--url="https://$DOMAIN_NAME" \
		--title="Inception" \
		--admin_user="$WP_ADMIN_USER" \
		--admin_password="$WP_ADMIN_PASSWORD" \
		--admin_email="$WP_ADMIN_EMAIL"

	wp user create \
		"$WP_USER" \
		"$WP_USER_EMAIL" \
		--user_pass="$WP_USER_PASSWORD" \
		--role=author \
		--allow-root \
		--path=/var/www/html
fi

exec	php-fpm8.2 -F
