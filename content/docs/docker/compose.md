---
title: "Docker Compose"
date: 2026-05-23
tags: ["docker", "compose", "yaml"]
source: doc/pages/docker/compose.md
source_sha: 317f9e40fa7d
---

> Multi-container apps in YAML: services, volumes, networks, .env, overrides, profiles.

## v1 vs v2

- **v2** (`docker compose ...`, Go plugin) — current, maintained. Use this.
- **v1** (`docker-compose ...`, Python) — deprecated.

## The Compose file

Reads `compose.yaml` (or `compose.yml`, `docker-compose.yaml`). Use `-f` for another path. v2 does NOT need `version:`.

Minimal:
```yaml
services:
  web:
    image: nginx:1.27
    ports:
      - "8080:80"
```

`docker compose up` → pull, network `<dir>_default`, container `<dir>-web-1`, start, stream logs. `Ctrl+C` stops; `docker compose down` removes.

## Real example — app + Postgres

```yaml
services:
  app:
    build: .
    # image: ghcr.io/me/app:1.0
    container_name: app
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      DATABASE_URL: postgres://app:${DB_PASSWORD}@db:5432/appdb
      LOG_LEVEL: info
    ports:
      - "8080:8080"
    networks:
      - backend

  db:
    image: postgres:16
    container_name: db
    restart: unless-stopped
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: appdb
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d appdb"]
      interval: 5s
      timeout: 3s
      retries: 10

volumes:
  pgdata:

networks:
  backend:
```

Notes:
- DB has no `-p` — only reachable from `app` via shared network.
- `depends_on` + `condition: service_healthy` waits for healthcheck (not just container start).
- `${DB_PASSWORD}` substituted from `.env`.
- Top-level `volumes:` / `networks:` declare named resources.

## .env

```
# .env
DB_PASSWORD=correcthorsebatterystaple
```

Keep `.env` out of git; commit `.env.example` with placeholders.

`.env` is for YAML substitution only. To make those values available inside containers, map via `environment:` or `env_file:`:

```yaml
services:
  app:
    image: myapp
    env_file:
      - .env.app
```

## Common commands

- Start (foreground):
  `docker compose up`

- Detached:
  `docker compose up -d`

- Force recreate:
  `docker compose up -d --force-recreate`

- Build first:
  `docker compose up -d --build`

- Stop (keep containers):
  `docker compose stop`

- Stop + remove containers + networks:
  `docker compose down`

- Down + volumes (destructive!):
  `docker compose down -v`

- Pull newer images:
  `docker compose pull`

- Status:
  `docker compose ps`

- Tail all logs:
  `docker compose logs -f`

- One service:
  `docker compose logs -f app`

- Exec (uses service name):
  `docker compose exec app sh`
  `docker compose exec db psql -U app -d appdb`

- One-off container:
  `docker compose run --rm app npm test`

- Restart service:
  `docker compose restart app`

- Show merged final config:
  `docker compose config`

- Build images:
  `docker compose build`

## Override files

Compose auto-merges `compose.yaml` + `compose.override.yaml`. For other names, multiple `-f`:

- Prod base only:
  `docker compose -f compose.yaml up -d`

- Dev (base + override):
  `docker compose -f compose.yaml -f compose.dev.yaml up -d`

Typical `compose.dev.yaml`:
```yaml
services:
  app:
    build:
      context: .
      target: dev
    volumes:
      - ./src:/app/src
    environment:
      LOG_LEVEL: debug
    ports:
      - "127.0.0.1:8080:8080"
```

## Profiles

Tag services with profiles to make them opt-in:

```yaml
services:
  app:
    image: myapp
  db:
    image: postgres:16
  pgadmin:
    image: dpage/pgadmin4
    profiles: [tools]
```

- Default (no profile):
  `docker compose up -d`

- Include tools:
  `docker compose --profile tools up -d`

## Useful patterns

- Restart misbehaving:
  ```
  docker compose restart app
  docker compose pull app
  docker compose up -d --force-recreate app
  ```

- Wipe stateful service:
  ```
  docker compose stop db
  docker compose rm -f db
  docker volume rm $(basename $PWD)_pgdata
  docker compose up -d db
  ```

- Validate before applying:
  `docker compose -f compose.yaml -f compose.prod.yaml config`

## Quick reference

| Command | Purpose |
|---------|---------|
| `docker compose up [-d]` | start |
| `docker compose down [-v]` | stop + remove |
| `docker compose ps` | list project containers |
| `docker compose logs -f [SVC]` | tail logs |
| `docker compose exec SVC CMD` | run in running service |
| `docker compose run --rm SVC CMD` | one-off container |
| `docker compose build [SVC]` | build images |
| `docker compose pull [SVC]` | pull images |
| `docker compose restart [SVC]` | restart |
| `docker compose config` | merged config |
| `docker compose --profile P up` | include profile |
