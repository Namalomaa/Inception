build:
	docker compose -f ./srcs/docker-compose.yml build

up:
	docker compose -f ./srcs/docker-compose.yml up

stop:
	docker compose -f ./srcs/docker-compose.yml stop

clean:
	docker compose -f ./srcs/docker-compose.yml down

.PHONY:	build up stop clean
