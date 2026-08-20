#!/bin/bash

set -e

: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is not set}"
: "${MYSQL_DATABASE:?MYSQL_DATABASE is not set}"
: "${MYSQL_USER:?MYSQL_USER is not set}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is not set}"


mkdir -p /run/mysqld
mkdir -p /var/log/mysql

chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql
chown -R mysql:mysql /var/log/mysql


if [ ! -d "/var/lib/mysql/mysql" ]; then
	
	echo "Initializing MariaDB..."
	mariadb-install-db \
	--user=mysql \
	--datadir=/var/lib/mysql \
	--auth-root-authentication-method=normal

	cat > /tmp/init.sql <<-EOF
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
		CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
		FLUSH PRIVILEGES;
EOF
	echo "Starting MariaDB..."
	exec /usr/sbin/mariadbd \
	--user=mysql \
	--init-file=/tmp/init.sql
else
	echo "Database already initialized."
	echo "Starting MariaDB..."
	
	exec /usr/sbin/mariadbd \
	--user=mysql
fi
