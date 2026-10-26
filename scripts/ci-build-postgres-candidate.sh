#!/usr/bin/env sh
set -eu

: "${DRONE_BUILD_NUMBER:?Drone build number is required}"
: "${DRONE_BUILD_EVENT:?Drone build event is required}"
: "${DRONE_BRANCH:?Drone branch is required}"
: "${DRONE_COMMIT_SHA:?Drone commit SHA is required}"

if [ "$DRONE_BUILD_EVENT" != push ] || [ "$DRONE_BRANCH" != 18 ]; then
  printf '%s\n' 'PostgreSQL candidates are allowed only on pushes to the 18 maintenance branch.' >&2
  exit 1
fi

base_ref=$(awk '$1 == "FROM" && $2 ~ /^kernel528\/alpine:/ { print $2; exit }' Dockerfile)
base_tag=${base_ref##*:}
expected_alpine=${base_tag%_*}
pg_version=$(awk '$1 == "ENV" && $2 == "PG_VERSION" { print $3; exit }' Dockerfile)
postgres_version="${pg_version}.0"
image="localhost/postgres-candidate:${DRONE_BUILD_NUMBER}-${DRONE_COMMIT_SHA}"
candidate_tag="${postgres_version}-${base_tag}-drone-build-${DRONE_BUILD_NUMBER}-amd64"

if [ -z "$base_tag" ] || [ -z "$expected_alpine" ] || [ -z "$pg_version" ]; then
  printf '%s\n' 'Could not determine the pinned Alpine base or PostgreSQL version.' >&2
  exit 1
fi

attempt=0
until docker info >/dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 60 ]; then
    printf '%s\n' 'Docker-in-Docker service did not become ready.' >&2
    exit 1
  fi
  sleep 1
done

docker build --pull --no-cache --tag "$image" .
image_id=$(docker image inspect --format '{{.Id}}' "$image")
printf 'PostgreSQL candidate image ID: %s\n' "$image_id"
printf 'PostgreSQL candidate tag after publish: %s\n' "$candidate_tag"
scripts/ci-smoke-postgres-image.sh "$image_id" "$expected_alpine" "$pg_version"

umask 077
printf '%s\n' "$image_id" > .drone-postgres-image-id
printf '%s\n' "$candidate_tag" > .drone-postgres-image-tag
printf '%s\n' "$DRONE_COMMIT_SHA" > .drone-postgres-commit
