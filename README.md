[![Build Status](https://drone.kernelsanders.biz:8443/api/badges/kernel528/postgres-docker/status.svg?ref=refs/heads/main)](https://drone.kernelsanders.biz:8443/kernel528/postgres-docker)
[![Latest Version](https://img.shields.io/github/v/tag/kernel528/postgres-docker)](https://github.com/kernel528/postgres-docker/releases/latest)
[![Docker Pulls](https://img.shields.io/docker/pulls/kernel528/postgres)](https://hub.docker.com/r/kernel528/postgres)
[![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/kernel528/postgres)](https://hub.docker.com/r/kernel528/postgres)
[![Docker Image Version (latest by date)](https://img.shields.io/docker/v/kernel528/postgres)](https://hub.docker.com/r/kernel528/postgres)

# Postgres Docker Image
Small PostgreSQL image built from the official Docker Library Alpine image and the custom `kernel528/alpine` base.

Based on: [Postgres Official Docker - Alpine](https://github.com/docker-library/postgres)

## Build
```
docker image build -t kernel528/postgres:18.6.0-261025 -f Dockerfile .
```

## Run
```
docker run -it -d -p 5432:5432 --name postgres-local -e POSTGRES_PASSWORD=password --hostname=postgres-local -d kernel528/postgres:18.6.0-261025
```

## Configuration
Common environment variables (aligned with the official Postgres image):
- `POSTGRES_PASSWORD` (required unless `POSTGRES_HOST_AUTH_METHOD=trust`)
- `POSTGRES_USER` (default: `postgres`)
- `POSTGRES_DB` (default: same as `POSTGRES_USER`)
- `POSTGRES_INITDB_ARGS` (extra `initdb` args)
- `POSTGRES_INITDB_WALDIR` (optional WAL directory)
- `POSTGRES_HOST_AUTH_METHOD` (e.g., `md5`, `scram-sha-256`, `trust`)
- `PGDATA` (Postgres 18 default: `/var/lib/postgresql/18/docker`)

Initialization scripts:
- Mount or copy `.sh`, `.sql`, `.sql.gz`, `.sql.xz`, or `.sql.zst` files into `/docker-entrypoint-initdb.d` to run on first startup.

Data persistence:
- Mount a volume to `/var/lib/postgresql` to keep Postgres 18 data across container restarts.

### Example: data volume + init script
```
docker run -it -d \
  --name postgres-local \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=password \
  -v postgres-data:/var/lib/postgresql \
  -v "$(pwd)/sample-postgres-db.sql:/docker-entrypoint-initdb.d/01-sample.sql:ro" \
  kernel528/postgres:18.6.0-261025
```

## Tagging
- Major-version tags track PostgreSQL release lines (for example, `18` or `16`).
- Date suffixes (for example, `16.11.0-260101`) indicate rebuilds or base-image updates for the same Postgres version.
- `latest` points to the most recently published image.

## Repository Relationships and Refresh Policy

This independent repository is coordinated by [`docker-workspace`](https://github.com/kernel528/docker-workspace), directly consumes [`kernel528/alpine`](https://github.com/kernel528/alpine-docker), and publishes images used by [`docker-swarm`](https://github.com/kernel528/docker-swarm). PostgreSQL has its own application-release cadence, but it must also be rebuilt when the shared Alpine base changes.

## CI validation and release policy

- Pull requests targeting `18` run rootless exact-image PostgreSQL checks, including a disposable-volume initialization, SQL write, clean shutdown, restart, and readback; the job publishes nothing.
- Pushes to `18` build and smoke-test a fresh DIND candidate before a separate credentialed step publishes a unique build-number candidate tag.
- Git tags from reviewed `main` use `18.6.0-YYMMDD`; the tag pipeline freshly builds and smoke-tests the immutable release before moving `18` and `latest`.
- Candidate tags are not deployment inputs. The CI test volume is temporary; no Swarm volume or production data is changed.
- This repository is public and trusted in Drone; add it to the isolated runner's exact repository allowlist only after pipeline review. Rootless PR jobs receive no registry credentials.

Publish and verify the Alpine tag first. Build and validate PostgreSQL with a disposable volume, including initialization, write, clean shutdown, restart, and persistence checks. Publish an immutable PostgreSQL tag before updating `stacks/postgress-stack.yml`. Treat the NFS-backed Swarm rollout as a separate change with a confirmed backup and previous image tag available for rollback.

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
docker container run -it --rm --name psql-client --hostname psql-client kernel528/postgres:18.6.0-261025 psql -h 192.168.1.110 -U postgres
<password>
select VERSION();
\q
```

## Sources
- https://www.postgresql.org/download/
