---
title: "Docker containers"
date: 2026-05-23
tags: ["docker", "containers", "run"]
source: doc/pages/docker/containers.md
source_sha: e76464fcbb65
---

> docker run, ps, start/stop/restart, exec, logs, rm, flags, restart policies.

## `docker run` basics

`docker run` = pull (if needed) + create + start. By default attached to terminal; `-d` detaches.

- Foreground:
  `docker run nginx`

- Detached + named:
  `docker run -d --name web nginx`

- One-off, auto-remove:
  `docker run --rm alpine echo "hello"`

- Interactive shell:
  `docker run --rm -it alpine sh`

- Override CMD:
  `docker run --rm alpine cat /etc/os-release`

Args after image name replace image's default `CMD`. `ENTRYPOINT` (if any) still runs.

## Common flags

| Flag | Purpose | Example |
|------|---------|---------|
| `-d` | detached | `docker run -d nginx` |
| `-it` | interactive + TTY | `docker run -it alpine sh` |
| `--name N` | name | `--name web` |
| `--rm` | remove on exit | `docker run --rm alpine date` |
| `-p H:C` | publish port | `-p 8080:80` |
| `-e K=V` | env var | `-e POSTGRES_PASSWORD=dev` |
| `--env-file F` | load env from file | `--env-file .env` |
| `-v V:/path` | volume / bind | `-v pgdata:/var/lib/postgresql/data` |
| `-w /path` | working dir | `-w /app` |
| `-u UID:GID` | run as user | `-u 1000:1000` |
| `--restart P` | restart policy | `--restart unless-stopped` |
| `--network N` | attach network | `--network appnet` |
| `--memory M` | memory limit | `--memory 512m` |
| `--cpus N` | CPU limit | `--cpus 1.5` |
| `--hostname H` | hostname | `--hostname db` |
| `--platform P` | force platform | `--platform linux/amd64` |

## Restart policies

| Policy | Behavior |
|--------|----------|
| `no` (default) | never restart |
| `on-failure[:N]` | restart on non-zero exit (optionally N times) |
| `always` | restart whenever stopped |
| `unless-stopped` | like always but respects manual `docker stop` |

Recommended for services: `--restart unless-stopped`.

## List

- Running:
  `docker ps`

- All:
  `docker ps -a`

- IDs only:
  `docker ps -aq`

- Filter:
  `docker ps --filter "status=exited"`
  `docker ps --filter "name=web"`

- Custom format:
  `docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"`

- Disk usage:
  `docker ps -s`

## Inspect

- Full JSON:
  `docker inspect web`

- Specific field:
  `docker inspect --format '{{.State.Status}}' web`
  `docker inspect --format '{{.NetworkSettings.IPAddress}}' web`

- Live resource stats (one-shot):
  `docker stats --no-stream`

- Processes inside:
  `docker top web`

## Logs

- Dump:
  `docker logs web`

- Follow:
  `docker logs -f web`

- Last N with timestamps:
  `docker logs --tail=100 -t web`

- Recent:
  `docker logs --since=10m web`

- Range:
  `docker logs --since=2024-01-01T00:00:00 --until=2024-01-02T00:00:00 web`

> `docker logs` requires `json-file` or `journald` log driver. Cap log size in `daemon.json` or with `--log-opt max-size=10m`.

## Exec

- Interactive shell:
  `docker exec -it web sh`
  `docker exec -it web bash`         # if image has bash

- One command:
  `docker exec web cat /etc/nginx/nginx.conf`

- As different user:
  `docker exec -u root -it web sh`

- Working dir + env:
  `docker exec -w /var/log -e DEBUG=1 web ls -la`

`exec` only works on running containers; start first if stopped.

## Start / stop / restart / pause

- Graceful stop (SIGTERM then SIGKILL after 10s):
  `docker stop web`

- Custom grace:
  `docker stop -t 30 web`

- Start stopped:
  `docker start web`

- Restart:
  `docker restart web`

- Pause / unpause (cgroup freeze):
  `docker pause web` / `docker unpause web`

- SIGKILL:
  `docker kill web`

- Custom signal:
  `docker kill --signal=SIGHUP web`

## Remove

- Stopped:
  `docker rm web`

- Force (stops + removes):
  `docker rm -f web`

- All stopped:
  `docker container prune`

## Copy files

- Container → host:
  `docker cp web:/etc/nginx/nginx.conf ./nginx.conf`

- Host → container:
  `docker cp ./newconfig.conf web:/etc/nginx/nginx.conf`

- Whole dir:
  `docker cp web:/var/log/nginx ./nginx-logs`

## Practical examples

### Postgres for dev (persistent)

```
docker run -d \
  --name pg \
  --restart unless-stopped \
  -p 5432:5432 \
  -e POSTGRES_USER=dev \
  -e POSTGRES_PASSWORD=dev \
  -e POSTGRES_DB=devdb \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16

docker exec -it pg psql -U dev -d devdb
```

### Redis

```
docker run -d \
  --name redis \
  --restart unless-stopped \
  -p 6379:6379 \
  redis:7-alpine

docker exec -it redis redis-cli
```

### Shell sandbox

```
docker run --rm -it alpine sh
docker run --rm -it debian:bookworm-slim bash
```

### Bind-mounted nginx with hot config reload

```
docker run -d \
  --name web \
  --restart unless-stopped \
  -p 80:80 \
  -v "$(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro" \
  -v "$(pwd)/site:/usr/share/nginx/html:ro" \
  nginx:1.27

docker exec web nginx -s reload
```

### Throwaway build environment

```
docker run --rm \
  -v "$(pwd)":/src \
  -w /src \
  golang:1.22 \
  go build -o myapp ./cmd/myapp
```

## Quick reference

| Goal | Command |
|------|---------|
| run + detach + name | `docker run -d --name N image` |
| interactive shell | `docker run --rm -it image sh` |
| list running | `docker ps` |
| list all | `docker ps -a` |
| stop/start/restart | `docker stop\|start\|restart N` |
| shell into | `docker exec -it N sh` |
| follow logs | `docker logs -f N` |
| inspect | `docker inspect N` |
| remove | `docker rm [-f] N` |
| stats | `docker stats` |
| copy | `docker cp N:/path ./local` |
