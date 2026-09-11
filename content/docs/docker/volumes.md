---
title: "Docker volumes"
date: 2026-05-23
tags: ["docker", "volumes", "storage"]
source: doc/pages/docker/volumes.md
source_sha: e3f681a00d4e
---

> Named volumes, bind mounts, tmpfs, backup pattern.

## Three storage types

| | Bind mount | Named volume | tmpfs |
|-|-----------|--------------|-------|
| Where | any host path | `/var/lib/docker/volumes/<name>/_data` | RAM |
| Managed by Docker | no | yes | n/a |
| Survives removal | yes (you own it) | until `docker volume rm` | no |
| Portable | no (host path) | yes (name only — data must be exported) | n/a |
| Performance | native | native | fastest |
| Use case | dev source / host config / host log dirs | DB state, opaque app data | secrets, scratch |

Rule of thumb:
- Edit data from host → bind mount.
- Opaque container state → named volume.
- Sensitive / scratch / disappears with container → tmpfs.

## `-v` vs `--mount` syntax

```
# Short
docker run -v pgdata:/var/lib/postgresql/data postgres:16
docker run -v "$(pwd)/src":/app/src postgres:16

# Long
docker run --mount type=volume,source=pgdata,target=/var/lib/postgresql/data postgres:16
docker run --mount type=bind,source="$(pwd)/src",target=/app/src postgres:16
docker run --mount type=tmpfs,target=/tmp,tmpfs-size=64m postgres:16
```

## Named volumes

- Create:
  `docker volume create pgdata`

- List:
  `docker volume ls`

- Inspect:
  `docker volume inspect pgdata`

- Where data actually lives:
  `sudo ls /var/lib/docker/volumes/pgdata/_data`

- Remove (must not be in use):
  `docker volume rm pgdata`

- Bulk unused:
  `docker volume prune`

- Mount in container:
  `docker run -d --name pg -v pgdata:/var/lib/postgresql/data -e POSTGRES_PASSWORD=dev postgres:16`

> First-time population: an empty named volume mounted onto a path that has content in the image causes Docker to copy the image's content into the volume. Once data is there, the mount "shadows" image contents.

## Bind mounts

- Absolute path required:
  `docker run -v /home/me/project:/app node:20`

- Current dir:
  `docker run -v "$(pwd)":/app node:20`

- Single file:
  `docker run -v "$(pwd)/nginx.conf":/etc/nginx/nginx.conf nginx`

- Read-only:
  `docker run -v "$(pwd)/nginx.conf":/etc/nginx/nginx.conf:ro nginx`

> **Warning:** `-v ./src:/app` does NOT work — Docker treats `./src` as a volume name and creates an anonymous volume. Always absolute (e.g. `$(pwd)/src`).

### SELinux relabel (`:z` / `:Z`)

Fedora/RHEL/CentOS only:
- `:z` — shared label (multiple containers can share).
- `:Z` — private label (more restrictive).

`docker run -v "$(pwd)/data":/data:Z myimage`

Not needed on Arch / Debian / Ubuntu.

## tmpfs

- Size-capped tmpfs `/tmp`:
  `docker run --tmpfs /tmp:size=64m alpine sh`

- Long form:
  `docker run --mount type=tmpfs,target=/cache,tmpfs-size=128m alpine`

## Practical examples

### Persistent Postgres

```
docker volume create pgdata

docker run -d \
  --name pg \
  --restart unless-stopped \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=dev \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16
```

`docker rm -f pg` leaves the volume; recreate with same `-v` and it picks up where it left off.

### Live-reload dev with bind mount

```
docker run --rm -it \
  -v "$(pwd)":/app \
  -w /app \
  -p 3000:3000 \
  node:20 \
  npm run dev
```

### Read-only config

```
docker run -d \
  --name web \
  -p 80:80 \
  -v "$(pwd)/nginx.conf":/etc/nginx/nginx.conf:ro \
  nginx:1.27

docker exec web nginx -s reload
```

### tmpfs scratch

```
docker run --rm \
  --tmpfs /scratch:size=256m,mode=1777 \
  myimage \
  /scratch/run.sh
```

## Backup / restore

### Backup (volume → host tar)

```
docker run --rm \
  -v pgdata:/data:ro \
  -v "$(pwd)":/backup \
  alpine \
  tar czf /backup/pgdata-$(date +%F).tar.gz -C /data .
```

### Restore (host tar → volume)

```
docker run --rm \
  -v pgdata:/data \
  -v "$(pwd)":/backup \
  alpine \
  tar xzf /backup/pgdata-2025-01-15.tar.gz -C /data
```

> For Postgres specifically, prefer `pg_dump`/`pg_restore` against the running container — `tar` while Postgres writes can corrupt the backup. The `tar` trick is safe only when the service is stopped or data is read-only.

## VOLUME in Dockerfile

Declaring `VOLUME /var/lib/myapp` creates an **anonymous volume** if no mount is provided at run time. Mostly used as documentation. Disables build-time writes to that path after declaration — can surprise you. Prefer letting users mount named volumes themselves.

## Quick reference

| Goal | Syntax |
|------|--------|
| named volume | `-v name:/path` |
| bind mount (rw) | `-v /abs/host:/path` |
| bind mount (ro) | `-v /abs/host:/path:ro` |
| tmpfs | `--tmpfs /path[:size=N]` |
| explicit | `--mount type=bind\|volume\|tmpfs,source=...,target=...,readonly` |
| list | `docker volume ls` |
| inspect | `docker volume inspect NAME` |
| remove | `docker volume rm NAME` |
| cleanup | `docker volume prune` |
