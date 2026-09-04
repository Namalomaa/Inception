help:
	@echo "Available commands:"
	@echo "  make build   - Build the Docker images"
	@echo "  make up      - Create and start the containers"
	@echo "  make down    - Stop and remove containers"
	@echo "  make start   - Start existing stopped containers"
	@echo "  make stop    - Stop running containers"

build:
	docker compose -f ./srcs/docker-compose.yml build

up:
	docker compose -f ./srcs/docker-compose.yml up

down:
	docker compose -f ./srcs/docker-compose.yml down

start:
	docker compose -f ./srcs/docker-compose.yml start

stop:
	docker compose -f ./srcs/docker-compose.yml stop


.PHONY:	build up stop down start
