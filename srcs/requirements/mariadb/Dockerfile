FROM	debian:bookworm

RUN	apt-get update && \
	apt-get install -y mariadb-server && \
	rm -rf /var/lib/mysql/* && \
	rm -rf /var/lib/apt/lists/*

RUN	mkdir -p /run/mysqld \
	&& mkdir -p /var/log/mysql \
	&& chown -R mysql:mysql /run/mysqld \
	&& chown -R mysql:mysql /var/log/mysql

COPY	conf/mariadb.cnf /etc/mysql/mariadb.conf.d/
COPY	tools/mariadb.sh /usr/local/bin/

RUN	chmod +x /usr/local/bin/mariadb.sh

EXPOSE	3306

ENTRYPOINT ["/usr/local/bin/mariadb.sh"]
