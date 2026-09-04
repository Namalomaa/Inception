# User Documentation

This document explains how to use the Inception stack after it has been installed.

## 1. What the Stack Provides

The project provides a small WordPress website built from three services:

| Service | Role |
|---|---|
| NGINX | Receives HTTPS requests and serves the web entry point. |
| WordPress + PHP-FPM | Runs the WordPress website and administration panel. |
| MariaDB | Stores WordPress data in a database. |

NGINX is the public entry point. WordPress and MariaDB communicate internally through the Docker network.

## 2. Start the Stack

From the project root:

```bash
make
```

Or, from the directory containing `docker-compose.yml`:

```bash
docker compose up -d --build
```

Check that the containers are running:

```bash
docker compose ps
```

## 3. Stop the Stack

To stop and remove the containers:

```bash
make down
```

or:

```bash
docker compose down
```

The persistent volumes are normally kept, so WordPress and MariaDB data remain available the next time the stack is started.

To remove the volumes as well:

```bash
docker compose down -v
```

Use this carefully because it removes the persistent application/database data stored in those volumes.

## 4. Open the Website

Open:

```text
https://namaloma.42.fr
```

The site uses HTTPS on port `443`.

If the browser reports that the certificate is not trusted, this is expected when using the project's locally generated/self-signed certificate. The warning can be accepted for local testing if the certificate and domain are the ones configured by the project.

## 5. Open the WordPress Administration Panel

Open:

```text
https://namaloma.42.fr/wp-admin
```

Use the WordPress administrator credentials configured for the project.

## 6. Find and Manage Credentials

Credentials are stored in the project's `secrets/` directory.

Typical files are:

```text
srcs/secrets/db_pass.txt
srcs/secrets/db_root_pass.txt
srcs/secrets/wp_admin_pass.txt
srcs/secrets/wp_user_pass.txt
```

The files contain passwords only. Usernames and other WordPress settings can be defined in the project's environment/configuration.

### Important

Do not upload real secret files to a public Git repository.

If a password must be changed:

1. Update the corresponding secret file.
2. Recreate the service if the initialization/configuration needs to read the new value.
3. Verify the application after restarting the stack.

Changing a secret does not automatically change a password that has already been written into the MariaDB database. For an already initialized database, the database/WordPress password may need to be changed through the appropriate application or database administration procedure.

## 7. Check That Everything Is Working

### Check containers

```bash
docker ps
```

You should see the NGINX, WordPress and MariaDB containers running.

### Check Compose status

```bash
docker compose ps
```

### Check logs

```bash
docker compose logs
```

For one service:

```bash
docker compose logs -f nginx
docker compose logs -f wordpress
docker compose logs -f mariadb
```

### Check MariaDB health

The MariaDB service has a healthcheck based on `mariadb-admin ping`.

```bash
docker inspect mariadb --format '{{.State.Health.Status}}'
```

A healthy service should report:

```text
healthy
```

### Check the HTTPS port

From the Docker host:

```bash
ss -lnt | grep 443
```

NGINX should be listening on port `443`.

## 8. Common Problems

### The website does not open

Check:

```bash
docker compose ps
docker compose logs nginx
docker compose logs wordpress
```

Also make sure the domain points to the correct machine.

### The browser shows an SSL warning

A self-signed certificate is not trusted by default. Check that you are using the expected project domain and certificate. For local development, the browser warning can be accepted.

### WordPress cannot connect to the database

Check MariaDB first:

```bash
docker compose logs mariadb
docker inspect mariadb --format '{{.State.Health.Status}}'
```

Then check WordPress:

```bash
docker compose logs wordpress
```

### Data disappeared after restarting

Check that you did not remove the volumes:

```bash
docker volume ls
```

`docker compose down` keeps named volumes by default. `docker compose down -v` removes them.

## 9. Data Persistence

The important application data is stored outside the container filesystem in Docker volumes. This is why recreating containers does not normally erase the website or database.

The container can be removed and created again while the volume containing the data remains.

## 10. Useful Everyday Commands

Start:

```bash
docker compose up -d
```

Stop:

```bash
docker compose down
```

Restart:

```bash
docker compose restart
```

View status:

```bash
docker compose ps
```

View logs:

```bash
docker compose logs -f
```

List volumes:

```bash
docker volume ls
```
