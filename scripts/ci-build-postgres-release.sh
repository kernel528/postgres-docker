#!/usr/bin/env sh
set -eu

: "${DRONE_BUILD_NUMBER:?Drone build number is required}"
: "${DRONE_BUILD_EVENT:?Drone build event is required}"
: "${DRONE_TAG:?Release tag is required}"
: "${DRONE_COMMIT_REF:?Git ref is required}"
: "${DRONE_COMMIT_SHA:?Commit SHA is required}"

if [ "$DRONE_BUILD_EVENT" != tag ] || [ "$DRONE_COMMIT_REF" != "refs/tags/$DRONE_TAG" ]; then
  printf '%s\n' 'PostgreSQL release builds require their matching Git tag event.' >&2
  exit 1
fi

base_ref=$(awk '$1 == "FROM" && $2 ~ /^kernel528\/alpine:/ { print $2; exit }' Dockerfile)
base_tag=${base_ref##*:}
expected_alpine=${base_tag%_*}
pg_version=$(awk '$1 == "ENV" && $2 == "PG_VERSION" { print $3; exit }' Dockerfile)
postgres_version="${pg_version}.0"
release_date=${DRONE_TAG#"${postgres_version}-"}
expected_tag="${postgres_version}-${release_date}"
image="localhost/postgres-release:${DRONE_BUILD_NUMBER}-${DRONE_COMMIT_SHA}"

case "$DRONE_TAG" in
  "${postgres_version}-"*) ;;
  *) printf 'PostgreSQL release tag must start with %s-.\n' "$postgres_version" >&2; exit 1 ;;
esac
case "$release_date" in
  ??????) ;;
  *) printf 'PostgreSQL release tag must end in a six-digit YYMMDD date: %s\n' "$DRONE_TAG" >&2; exit 1 ;;
esac
case "$release_date" in
  *[!0-9]*) printf 'PostgreSQL release date must be numeric: %s\n' "$release_date" >&2; exit 1 ;;
esac
if [ "$DRONE_TAG" != "$expected_tag" ]; then
  printf 'PostgreSQL release tag mismatch: expected %s, got %s.\n' "$expected_tag" "$DRONE_TAG" >&2
  exit 1
fi

if ! awk -v tag="- ${DRONE_TAG}:" 'index($0, tag) == 1 { found = 1 } END { exit !found }' VERSION.md; then
  printf 'PostgreSQL release tag %s is not recorded in VERSION.md.\n' "$DRONE_TAG" >&2
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
printf 'PostgreSQL release source commit: %s\n' "$DRONE_COMMIT_SHA"
printf 'PostgreSQL release tag: %s\n' "$DRONE_TAG"
printf 'PostgreSQL release image ID: %s\n' "$image_id"
scripts/ci-smoke-postgres-image.sh "$image_id" "$expected_alpine" "$pg_version"

umask 077
printf '%s\n' "$image_id" > .drone-postgres-image-id
printf '%s\n' "$DRONE_TAG" > .drone-postgres-release-tag
printf '%s\n' "$DRONE_COMMIT_SHA" > .drone-postgres-commit
