# Repository Guidelines

## Project Structure & Module Organization
- `Dockerfile` builds the Postgres image (from kernel528/alpine).
- `docker-entrypoint.sh` and `docker-ensure-initdb.sh` provide runtime init logic.
- `sample-postgres-db.sql` is a seed example used for init scripts.
- `README.md` documents build/run/test usage; `VERSION.md` tracks releases.

## Build, Test, and Development Commands
Use the latest tag from `VERSION.md` in examples; update these if the tag changes.
- Build the image locally:
  ```sh
  docker image build -t kernel528/postgres:18.4.0-260718 -f Dockerfile .
  ```
- Run a container:
  ```sh
  docker run -it -d -p 5432:5432 --name postgres-local -e POSTGRES_PASSWORD=password -d kernel528/postgres:18.4.0-260718
  ```
- Manual smoke test (inside container):
  ```sh
  docker exec -it postgres-local sh
  su postgres
  psql
  select version();
  ```

## Coding Style & Naming Conventions
- Shell scripts are Bash (`#!/usr/bin/env bash`) with `set -Eeo pipefail`.
- Keep scripts POSIX-friendly where possible; avoid heavy dependencies.
- Prefer clear, sentence-case log messages (see `docker-entrypoint.sh`).

## Testing Guidelines
- No automated test suite is included.
- Use the manual `psql` checks in `README.md` for validation after changes.
- If changing init logic, verify a fresh volume initialization.

## Commit & Pull Request Guidelines
- Commit messages in history are concise, imperative, and specific (e.g., “Updated base image…”, “Fixed …”).
- PRs should:
  - describe the change and rationale,
  - include version bumps in `VERSION.md` when image components change,
  - update `README.md` examples if tags or behavior change.

## Release Checklist
- Update `Dockerfile` base image or Postgres version (if applicable).
- Add a new entry to `VERSION.md`.
- Update `README.md` example tags to the new version.
- Build and run locally; verify `psql` connects.
- Merge via PR with a clear summary of changes.

## Base Image Notes
- The `Dockerfile` depends on `kernel528/alpine`. If the base image tag changes, build and publish `kernel528/alpine:<version>` first, then bump the `FROM` line here.

## Security & Configuration Tips
- Always set `POSTGRES_PASSWORD` unless deliberately using `POSTGRES_HOST_AUTH_METHOD=trust` (not recommended).
- Use `/docker-entrypoint-initdb.d` for first-run `.sql` or `.sh` init scripts.
