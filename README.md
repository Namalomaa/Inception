*This activity has been created as part of the 42 curriculum by namaloma.*

# Inception

## Description

Inception is a system administration project focused on building a small web infrastructure with Docker and Docker Compose.

The stack is made of three services:

- **NGINX** — the only public-facing service. It accepts HTTPS connections on port `443` and forwards PHP requests to WordPress.
- **WordPress + PHP-FPM** — the web application that provides the website and administration panel.
- **MariaDB** — the database used by WordPress.

The main goal is to build the infrastructure from our own Dockerfiles and configuration files instead of relying on ready-made application containers. The services communicate through a private Docker network, while persistent data is stored in Docker volumes.

## Project Description

The project uses Docker to isolate each service in its own container while keeping the whole application easy to build and reproduce with Docker Compose.

### Main design choices

- **Three dedicated containers:** NGINX, WordPress/PHP-FPM, and MariaDB.
- **Custom Dockerfiles:** each service is built from a Debian base image and configured for the needs of the project.
- **NGINX as the entry point:** only HTTPS port `443` is exposed to the host.
- **PHP-FPM:** WordPress does not run PHP directly through NGINX; NGINX sends PHP requests to PHP-FPM on port `9000` over the Docker network.
- **MariaDB isolation:** the database is not directly exposed to the host; WordPress reaches it through the Docker network.
- **Private Docker network:** service names such as `wordpress` and `mariadb` are used for internal communication instead of host IP addresses.
- **Healthcheck:** MariaDB is checked with `mariadb-admin ping` so that its readiness can be verified.
- **Secrets:** passwords are kept outside the image and configuration files, in the project's `secrets/` directory.
- **TLS:** NGINX uses an SSL/TLS certificate created with OpenSSL. The certificate is configured for the project domain, such as `namaloma.42.fr`.
- **Persistent storage:** WordPress files and MariaDB data are stored in Docker volumes so that recreating containers does not remove application data.
- **Daemon/foreground behaviour:** services run their main server process in the foreground so the process remains attached to the container lifecycle.

### Virtual Machines vs Docker

| Virtual Machines | Docker |
|---|---|
| Virtualizes a complete operating system. | Shares the host kernel and isolates processes in containers. |
| Each VM normally needs its own OS and more resources. | Containers are lighter and usually start faster. |
| Strong isolation between complete operating systems. | Application/service-level isolation. |
| Useful when different kernels or complete machines are needed. | Well suited for packaging a multi-service application. |

For this project, Docker is a better fit because NGINX, WordPress and MariaDB need isolated environments, but they do not need three complete operating systems.

### Secrets vs Environment Variables

| Secrets | Environment Variables |
|---|---|
| Intended for sensitive values such as passwords. | Convenient for configuration values. |
| Can be provided as files and kept separate from ordinary configuration. | Easy to inspect from container/process configuration. |
| Better suited for credentials. | Better suited for non-sensitive settings. |

In this project, passwords are stored in secret files and read by the initialization scripts. Ordinary configuration can still be passed through environment variables where appropriate.

### Docker Network vs Host Network

| Docker Network | Host Network |
|---|---|
| Containers communicate through an isolated Docker network. | Containers use the host's network stack directly. |
| Containers can reach each other by service name. | Less network isolation. |
| Internal services do not need to publish every port to the host. | Can reduce network overhead, but exposes services more directly to the host network. |

This project uses a Docker bridge network so that NGINX can reach WordPress and WordPress can reach MariaDB internally, while only HTTPS is published to the host.

### Docker Volumes vs Bind Mounts

| Docker Volumes | Bind Mounts |
|---|---|
| Docker manages the storage location. | The host path is chosen explicitly. |
| Useful for application data that should survive container recreation. | Useful when the host needs direct access to the files. |
| Less dependent on a specific host directory. | Easier to inspect/edit directly from the host. |

This project uses Docker volumes for persistent WordPress and MariaDB data. This means `docker compose down` removes the containers and network, but normally keeps the data. Using `docker compose down -v` also removes the volumes and therefore deletes the persistent data.



## Instructions

### Prerequisites

You need:

- Linux or a Linux virtual machine.
- Docker Engine.
- Docker Compose v2.
- `make`.
- Git.
- Internet access while building the images, because packages and WordPress are downloaded during the build/initialization process.

### Configure the domain

The WordPress site is accessed through the project domain, for example:

```text
namaloma.42.fr
```

Make sure the domain resolves to the machine running Docker. In a local VM setup, this is commonly done by adding the domain to `/etc/hosts` with the VM's IP address.

### Start the project

From the repository root:

```bash
make
```

The Makefile should build the images and start the Compose stack.

You can also use Docker Compose directly from the directory containing `docker-compose.yml`:

```bash
docker compose up -d --build
```

### Stop the project

```bash
make down
```

or:

```bash
docker compose down
```

This stops and removes the containers and the Compose network, but normally keeps named volumes.

To remove the volumes too:

```bash
docker compose down -v
```

**Warning:** removing the volumes deletes the persisted WordPress and MariaDB data stored in those volumes.

## Access

Website:

```text
https://namaloma.42.fr
```

WordPress administration:

```text
https://namaloma.42.fr/wp-admin
```

Because the project uses a self-signed certificate, a browser may show a security warning. For local development, this is expected unless the certificate has been trusted by the browser/system.

## Credentials

Credentials are not stored directly in the Dockerfiles.

They are kept in the `secrets/` directory, for example:

```text
srcs/secrets/db_pass.txt
srcs/secrets/db_root_pass.txt
srcs/secrets/wp_admin_pass.txt
srcs/secrets/wp_user_pass.txt
```

## Useful Commands

Check running containers:

```bash
docker ps
```

Check all Compose services:

```bash
docker compose ps
```

View logs:

```bash
docker compose logs
```

Follow logs for one service:

```bash
docker compose logs -f nginx
```

Open a shell inside a container:

```bash
docker exec -it wordpress bash
docker exec -it mariadb bash
docker exec -it nginx bash
```

Check the WordPress container configuration:

```bash
docker inspect wordpress
```

Check MariaDB health:

```bash
docker inspect mariadb --format '{{.State.Health.Status}}'
```

## Technical Notes

### Why PHP-FPM is used

NGINX is a web server and does not execute PHP itself. PHP-FPM provides the PHP process manager. NGINX forwards PHP requests to PHP-FPM using FastCGI, configured with:

```text
fastcgi_pass wordpress:9000;
```

### Why services run in the foreground

A container is normally alive while its main process is alive. Therefore NGINX, PHP-FPM and MariaDB must not simply start a background daemon and then exit. The main service process stays in the foreground so it acts as the container's main process.

### PID 1

The main process started by the container becomes PID 1 inside that container. Keeping the main service process as PID 1 helps Docker track the service lifecycle and allows termination signals to reach the correct process.

## Sources

Classic references used for the project:

- Docker Baisics — https://youtu.be/pg19Z8LL06w?si=1pWiAt5yZdyToWLl
- Docker Documentation — https://docs.docker.com/
- Docker Compose Documentation — https://docs.docker.com/compose/
- Docker secrets — https://docs.docker.com/engine/swarm/secrets/
- NGINX Documentation — https://nginx.org/en/docs/
- PHP-FPM — https://www.php.net/manual/en/install.fpm.php
- MariaDB guide — https://mariadb.com/docs/
- WordPress installation — https://make.wordpress.org/cli/handbook/guides/installing/#verifying-the-download-optional-but-recommended/
- WP-CLI Documentation — https://developer.wordpress.org/cli/commands/
- SSL handshake explaination — https://youtu.be/67Kfsmy_frM?si=QzHMdXSRTrhGPk2e
- OpenSSL Documentation — https://openssl-ca.readthedocs.io/en/latest/
- installing self-signed certificate  — https://docs.faveohelpdesk.com/docs/installation/providers/enterprise/self-signed-ssl-debian-nginx/



### How AI was used

AI was used as a learning and debugging assistant during the activity. It helped with:

- Understanding Docker concepts such as images, containers, volumes, networks, PID 1, foreground processes and daemon behaviour.
- Explaining Docker Compose commands and troubleshooting container lifecycle issues.
- Debugging MariaDB initialization scripts, healthchecks and container configuration.
- Understanding WordPress/PHP-FPM installation and WP-CLI usage.
- Troubleshooting SSL certificate configuration with OpenSSL.
- Explaining Docker volume storage and the difference between named volumes and bind mounts.
- Reviewing commands and configuration choices while keeping the final implementation under the developer's control.


