FROM	debian:12.15

RUN	apt-get update && \
	apt-get install -y mariadb-server && \
	rm -rf /var/lib/mysql/* && \
	rm -rf /var/lib/apt/lists/*

COPY	conf/mariadb.cnf /etc/mysql/mariadb.conf.d/
COPY	tools/mariadb.sh /mariadb.sh

RUN	chmod +x /mariadb.sh

EXPOSE	3306

HEALTHCHECK	--interval=5s --timeout=5s --retries=10 \
		CMD mariadb-admin ping -h localhost -u root \
		-p"$(cat /run/secrets/db_root_pass)" || exit 1

ENTRYPOINT	["/mariadb.sh"]
