#!/usr/bin/env sh
set -eu

image_id=${1:?Usage: ci-smoke-postgres-image.sh <image-id> <alpine-release> <postgres-version>}
expected_alpine=${2:?Usage: ci-smoke-postgres-image.sh <image-id> <alpine-release> <postgres-version>}
expected_postgres=${3:?Usage: ci-smoke-postgres-image.sh <image-id> <alpine-release> <postgres-version>}
smoke_id="postgres-smoke-$$"
smoke_volume="postgres-smoke-$$"
container_id=""
volume_created=0

cleanup() {
  rc=$?
  trap - EXIT
  if [ -n "$container_id" ]; then
    docker container rm --force "$container_id" >/dev/null 2>&1 || rc=1
  fi
  if [ "$volume_created" -eq 1 ]; then
    docker volume rm --force "$smoke_volume" >/dev/null 2>&1 || rc=1
  fi
  exit "$rc"
}
trap cleanup EXIT

actual_alpine=$(docker container run --rm "$image_id" cat /etc/alpine-release)
if [ "$actual_alpine" != "$expected_alpine" ]; then
  printf 'Alpine release mismatch: expected %s, got %s\n' "$expected_alpine" "$actual_alpine" >&2
  exit 1
fi

actual_postgres=$(docker container run --rm "$image_id" postgres --version 2>&1)
case "$actual_postgres" in
  *"$expected_postgres"*) ;;
  *) printf 'PostgreSQL version mismatch; expected %s, got %s\n' "$expected_postgres" "$actual_postgres" >&2; exit 1 ;;
esac

docker volume create "$smoke_volume" >/dev/null
volume_created=1
container_id=$(docker container create --name "$smoke_id" --volume "$smoke_volume:/var/lib/postgresql" \
  --env POSTGRES_PASSWORD=ci-smoke-only "$image_id")
docker container start "$container_id" >/dev/null

attempt=0
until docker container exec "$container_id" pg_isready --username=postgres --dbname=postgres >/dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 60 ]; then
    docker container logs "$container_id" >&2 || true
    printf '%s\n' 'PostgreSQL did not become ready within 60 seconds.' >&2
    exit 1
  fi
  sleep 1
done

docker container exec "$container_id" psql --no-psqlrc --set ON_ERROR_STOP=1 --username=postgres --dbname=postgres \
  --command "CREATE TABLE ci_smoke (id integer PRIMARY KEY, value text); INSERT INTO ci_smoke VALUES (1, 'persisted');" >/dev/null
docker container stop --time 30 "$container_id" >/dev/null
docker container rm "$container_id" >/dev/null
container_id=""

container_id=$(docker container create --name "$smoke_id" --volume "$smoke_volume:/var/lib/postgresql" \
  --env POSTGRES_PASSWORD=ci-smoke-only "$image_id")
docker container start "$container_id" >/dev/null
attempt=0
until docker container exec "$container_id" pg_isready --username=postgres --dbname=postgres >/dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 60 ]; then
    docker container logs "$container_id" >&2 || true
    printf '%s\n' 'PostgreSQL did not restart cleanly with its initialized data.' >&2
    exit 1
  fi
  sleep 1
done

actual_value=$(docker container exec "$container_id" psql --no-psqlrc --set ON_ERROR_STOP=1 \
  --username=postgres --dbname=postgres --tuples-only --no-align \
  --command 'SELECT value FROM ci_smoke WHERE id = 1')
if [ "$actual_value" != persisted ]; then
  printf 'PostgreSQL persistence smoke failed: expected persisted, got %s\n' "$actual_value" >&2
  exit 1
fi

docker container stop --time 30 "$container_id" >/dev/null
docker container rm "$container_id" >/dev/null
container_id=""
printf 'PostgreSQL smoke checks passed: Alpine %s, PostgreSQL %s, initialized data survived clean restart.\n' \
  "$actual_alpine" "$expected_postgres"
