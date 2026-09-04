# Developer Documentation

This document explains how to set up, build, run and maintain the Inception project.

## 1. Architecture

The stack contains three services:

```text
NGINX  <----HTTPS----  Browser
  |
  | FastCGI :9000
  v
WordPress / PHP-FPM
  |
  | MariaDB :3306
  v
MariaDB
```

All services are connected to the Docker Compose network.

Only NGINX needs to publish a host port. In the current setup this is:

```text
443:443
```

WordPress exposes PHP-FPM internally on:

```text
9000
```

MariaDB listens internally on:

```text
3306
```

## 2. Prerequisites

Install the following on the host or VM:

- Docker Engine
- Docker Compose v2
- GNU Make
- Git
- A Linux environment
- Internet access for package/image downloads during setup

Check the versions:

```bash
docker --version
docker compose version
make --version
git --version
```

The project can also be run inside a Linux VM. In that case, make sure the VM can reach the host/network and that the project domain resolves to the correct VM IP.

## 3. Repository Structure

A typical structure is:

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── srcs/
│   ├── docker-compose.yml
│   ├── .env
│   ├── requirements/
│   │   ├── mariadb/
│   │   │   ├── Dockerfile
│   │   │   └── tools/
│   │   │       └── mariadb.sh
│   │   ├── nginx/
│   │   │   ├── Dockerfile
│   │   │   └── conf/
│   │   │       └── nginx.conf
│   │   └── wordpress/
│   │       ├── Dockerfile
│   │       └── tools/
│   │           └── wordpress.sh
│   └── secrets/
│       ├── db_pass.txt
│       ├── db_root_pass.txt
│       ├── wp_admin_pass.txt
│       └── wp_user_pass.txt
└── data/
```

Adjust paths when your final repository uses a different layout.

## 4. Configuration Files

### `.env`

The `.env` file contains non-secret project configuration used by Docker Compose.

Do not put real passwords in `.env` when the project is using Docker secrets/files for credentials.

### `secrets/`

The secret directory contains passwords used by the initialization scripts. Typical files are:

```text
secrets/db_pass.txt
secrets/db_root_pass.txt
secrets/wp_admin_pass.txt
secrets/wp_user_pass.txt
```

Protect these files and keep them out of version control when they contain real credentials.

### `/etc/hosts`

For a local installation, map the project domain to the IP address of the machine/VM running NGINX.

Example:

```text
192.168.x.x    namaloma.42.fr
```

Use the actual IP address of the Docker host/VM.

## 5. Build and Launch with Makefile

From the repository root:

```bash
make
```

The Makefile is the main entry point for building and starting the project.

For a direct Docker Compose build/start:

```bash
cd srcs
docker compose up -d --build
```

To force a clean rebuild of the images:

```bash
docker compose build --no-cache
docker compose up -d
```

Avoid using `--no-cache` unless a clean rebuild is actually needed because it makes builds slower.

## 6. Container Lifecycle

### List containers

```bash
docker ps
docker compose ps
```

### Stop the project

```bash
docker compose down
```

This removes the project containers and Compose network but normally preserves named volumes.

### Stop and remove volumes

```bash
docker compose down -v
```

This also removes the volumes created for the Compose project. Use it only when you intentionally want to reset persistent data.

### Restart services

```bash
docker compose restart
```

### Start an existing stopped container

```bash
docker start wordpress
```

`docker stop` only stops a specific container. It does not remove the container.

`docker compose down` stops and removes the containers belonging to the Compose project.

## 7. Working with Containers

Open a shell:

```bash
docker exec -it wordpress bash
docker exec -it mariadb bash
docker exec -it nginx bash
```

Check the container entrypoint:

```bash
docker inspect wordpress --format '{{json .Config.Entrypoint}}'
```

Check the processes:

```bash
docker exec -it wordpress ps aux
docker exec -it mariadb ps aux
docker exec -it nginx ps aux
```

The important service process should remain in the foreground. A container exits when its main process exits.

## 8. NGINX / PHP-FPM

NGINX listens for HTTPS requests and passes PHP requests to WordPress/PHP-FPM through the Docker network.

The important relationship is:

```text
NGINX  --->  wordpress:9000
```

`wordpress` is the Compose service/container name, so Docker's internal DNS resolves it on the project network.

The NGINX configuration uses FastCGI parameters to pass information about the request to PHP-FPM.

Typical PHP handling includes a `location` block for PHP files and a `fastcgi_pass` directive.

NGINX does not execute PHP itself; PHP-FPM executes the PHP code.

## 9. MariaDB

The MariaDB image is built from Debian and installs the MariaDB server package.

The initialization script reads passwords from the secret files, configures MariaDB, and starts the database server.

The MariaDB healthcheck uses:

```bash
mariadb-admin ping -h localhost -u root -p"${MYSQL_ROOT_PASSWORD}"
```

A healthy result means MariaDB is responding to the healthcheck command.

The database service is normally reached by WordPress through the Compose network using the MariaDB service name rather than `localhost` from the WordPress container.

## 10. WordPress

The WordPress image is built from Debian and installs the required PHP components, including PHP-FPM and the MariaDB PHP extension.

The WordPress setup downloads WordPress and uses WP-CLI for installation/configuration tasks.

PHP-FPM listens on port `9000` inside the WordPress container so NGINX can forward FastCGI requests to it.

## 11. SSL/TLS

The NGINX image creates an SSL directory, for example:

```text
/etc/nginx/ssl
```

An OpenSSL-generated certificate is configured for the project domain.

The HTTPS listener is configured on port `443`.

A browser may report that the certificate is not trusted when the certificate is self-signed. This is normal for local development unless the certificate authority/certificate has been trusted by the client.

## 12. Volumes and Data Persistence

The persistent state of the project is stored in Docker volumes rather than only inside the writable container layers.

The two important data categories are:

- **MariaDB data** — database files.
- **WordPress data** — WordPress application/uploads/content files mounted as persistent storage according to the Compose configuration.

Because the data is kept in volumes, removing and recreating containers does not normally remove the data.

### Inspect volumes

```bash
docker volume ls
docker volume inspect <volume_name>
```

### Important distinction

```bash
docker compose down
```

removes containers and the network, but named volumes normally remain.

```bash
docker compose down -v
```

also removes the volumes.

Do not use `-v` when you want to preserve the existing database/WordPress data.

## 13. Docker Volumes vs Bind Mounts in This Project

A bind mount explicitly connects a host directory to a container path. A named Docker volume lets Docker manage the storage location.

For persistent application data, the project uses Docker volumes because the container should be replaceable without tying the application to a specific host directory.

The Docker-managed volume location can be inspected with:

```bash
docker volume inspect <volume_name>
```

Changing the path returned by Docker is not the same as changing a path in `docker-compose.yml`; the Compose file defines the mount type/name, while Docker manages where its named-volume data is stored on the host.

## 14. Networking

The Compose project creates a private network for the services.

The services can communicate using their Compose service names:

```text
nginx       -> wordpress:9000
wordpress   -> mariadb:3306
```

This is preferable to using the host network because internal traffic stays inside the isolated Docker network and internal services do not need to publish their ports to the host.

## 15. Logs and Troubleshooting

View all logs:

```bash
docker compose logs
```

Follow one service:

```bash
docker compose logs -f nginx
docker compose logs -f wordpress
docker compose logs -f mariadb
```

Check status:

```bash
docker compose ps
```

Check health:

```bash
docker inspect mariadb --format '{{.State.Health.Status}}'
```

Inspect configuration:

```bash
docker inspect nginx
docker inspect wordpress
docker inspect mariadb
```

### Common troubleshooting order

When the website is unavailable, check the stack in this order:

1. `docker compose ps`
2. MariaDB health/logs
3. WordPress logs
4. NGINX logs
5. Domain/`/etc/hosts`
6. Port `443`
7. SSL certificate/domain configuration

## 16. Security Notes

- Do not commit real passwords.
- Keep secret files out of public repositories.
- Expose only the ports that are actually required by the architecture.
- Keep MariaDB internal to the Docker network.
- Use HTTPS for the public web entry point.
- Do not place sensitive credentials directly inside Dockerfiles because Docker image layers can preserve build-time content.

## 17. Resetting the Environment

A full reset removes containers and persistent volumes:

```bash
docker compose down -v
```

Then rebuild and start again:

```bash
docker compose up -d --build
```

This is useful when testing the installation process from a clean state, but it also removes existing database/application data.

## 18. Useful Docker Concepts for This Project

### Image vs Container

An **image** is the packaged filesystem and configuration used to create a container.

A **container** is a running or stopped instance created from an image.

### `docker stop` vs `docker compose down`

```bash
docker stop wordpress
```

stops one container and keeps it.

```bash
docker compose down
```

stops and removes the containers belonging to the Compose project and removes the Compose network.

### PID 1

The main process started by the container is PID 1 inside that container. The container lifecycle follows this process, so server processes should stay in the foreground instead of starting a daemon and exiting.

Keeping the service process as the main container process also makes signal handling and shutdown behaviour easier to manage.

### Orphan vs Zombie Processes

An orphan process is a child whose original parent exited; it can be adopted by PID 1. A zombie process is a finished process that still has an entry in the process table because its parent has not collected its exit status.

They are different concepts. Proper process supervision and correct foreground/service behaviour help avoid process-management problems in the containers.
