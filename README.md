[![Build Status](http://drone.kernelsanders.biz:8080/api/badges/kernel528/postgres-docker/status.svg?ref=refs/heads/main)](http://drone.kernelsanders.biz:8080/kernel528/postgres-docker)
[![Latest Version](https://img.shields.io/github/v/tag/kernel528/postgres-docker)](https://github.com/kernel528/postgres-docker/releases/latest)
[![Docker Pulls](https://img.shields.io/docker/pulls/kernel528/postgres)](https://hub.docker.com/r/kernel528/postgres)
[![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/kernel528/postgres)](https://hub.docker.com/r/kernel528/postgres)
[![Docker Image Version (latest by date)](https://img.shields.io/docker/v/kernel528/postgres)](https://hub.docker.com/r/kernel528/postgres)

# Postgres Docker Image
Small, Alpine-based PostgreSQL image built from the official Docker Library image.

Based on: [Postgres Official Docker - Alpine](https://github.com/docker-library/postgres)

## Build
```
docker image build -t kernel528/postgres:18.1.0-260128 -f Dockerfile .
```

## Run
```
docker run -it -d -p 5432:5432 --name postgres-local -e POSTGRES_PASSWORD=password --hostname=postgres-local -d kernel528/postgres:18.1.0-260128
```

## Configuration
Common environment variables (aligned with the official Postgres image):
- `POSTGRES_PASSWORD` (required unless `POSTGRES_HOST_AUTH_METHOD=trust`)
- `POSTGRES_USER` (default: `postgres`)
- `POSTGRES_DB` (default: same as `POSTGRES_USER`)
- `POSTGRES_INITDB_ARGS` (extra `initdb` args)
- `POSTGRES_INITDB_WALDIR` (optional WAL directory)
- `POSTGRES_HOST_AUTH_METHOD` (e.g., `md5`, `scram-sha-256`, `trust`)
- `PGDATA` (default: `/var/lib/postgresql/data`)

Initialization scripts:
- Mount or copy `.sh`, `.sql`, `.sql.gz`, `.sql.xz`, or `.sql.zst` files into `/docker-entrypoint-initdb.d` to run on first startup.

Data persistence:
- Mount a volume to `/var/lib/postgresql/data` to keep data across container restarts.

### Example: data volume + init script
```
docker run -it -d \
  --name postgres-local \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=password \
  -v postgres-data:/var/lib/postgresql/data \
  -v "$(pwd)/sample-postgres-db.sql:/docker-entrypoint-initdb.d/01-sample.sql:ro" \
  kernel528/postgres:18.1.0-260128
```

## Tagging
- `16.x` tags track Postgres release versions (for example, `16.11.0`).
- Date suffixes (for example, `16.11.0-260101`) indicate rebuilds or base-image updates for the same Postgres version.
- `latest` points to the most recently published image.

## Test
Once the container is running, there are two ways to test.

### Inside the container
```
docker exec -it <container_name> sh
su postgres
psql
select VERSION();
\q
exit         # su
exit         # container
```

### From another host or container
If you have `psql` installed locally, or run it from a separate container:
```
docker container run -it --rm --name psql-client --hostname psql-client kernel528/postgres:18.1.0-260128 psql -h 192.168.1.110 -U postgres
<password>
select VERSION();
\q
```

## Sources
- https://www.postgresql.org/download/
