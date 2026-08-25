FROM	debian:12.15

RUN	apt-get update && \
	apt-get install -y nginx \
	openssl \
	&& rm -rf /var/lib/apt/lists/* 


RUN	mkdir -p /etc/nginx/ssl
RUN	openssl req -x509 -nodes \
	-days 365 -newkey rsa:2048 \
	-keyout /etc/nginx/ssl/inception.key \
	-out /etc/nginx/ssl/inception.crt \
	-subj "/C=JO/ST=IRBID/L=IRBID/O=42/CN=namaloma.42.fr"
#                        this is where the nginx stores its server configuration
COPY	conf/nginx.conf /etc/nginx/conf.d/default.conf


EXPOSE 443

CMD [ "nginx", "-g", "daemon off;"]
