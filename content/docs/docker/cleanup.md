---
title: "Docker cleanup"
date: 2026-05-23
tags: ["docker", "cleanup", "disk"]
source: doc/pages/docker/cleanup.md
source_sha: 3d4480787206
---

> Disk usage, pruning, log rotation, reclaiming space.

## What's using disk

- Summary:
  `docker system df`

- Per-resource breakdown:
  `docker system df -v`

Sample output of `docker system df`:
```
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          42        8         12.3GB    9.1GB (74%)
Containers      15        4         287MB     201MB (70%)
Local Volumes   23        6         4.5GB     2.1GB (46%)
Build Cache     128       0         3.2GB     3.2GB
```

## docker system prune

Removes unused containers, networks, dangling images, build cache. By default leaves named volumes alone and only deletes **dangling** images.

- Interactive:
  `docker system prune`

- No prompt:
  `docker system prune -f`

- Also all unused images:
  `docker system prune -a`

- Also unused volumes (destructive!):
  `docker system prune -a --volumes`

> **Warning:** `--volumes` deletes named volumes' data. Backup first (see `volumes`).

## Targeted prunes

### Containers

- All stopped:
  `docker container prune`

- Older than 24h:
  `docker container prune --filter "until=24h"`

### Images

- Dangling:
  `docker image prune`

- All unused:
  `docker image prune -a`

- By age (older than 30 days):
  `docker image prune -a --filter "until=720h"`

- By label:
  `docker image prune --filter "label!=keep"`

### Volumes

- Unused:
  `docker volume prune`

- Include anonymous (Docker 23+):
  `docker volume prune -a`

- By label:
  `docker volume prune --filter "label!=keep"`

### Networks

- Unused user-defined (built-ins never touched):
  `docker network prune`

### Build cache

- Default (keep recent):
  `docker builder prune`

- Everything:
  `docker builder prune -a`

- Limit by size:
  `docker builder prune --keep-storage 5GB`

## Container logs

`json-file` driver (default) grows without limit.

### Per-container

```
docker run -d \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  --name web \
  nginx
```

### Global via daemon.json

`/etc/docker/daemon.json`:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Apply with `sudo systemctl restart docker`. Existing containers keep old settings until recreated.

### Find / truncate log file

- Locate:
  `docker inspect --format '{{.LogPath}}' web`

- View size:
  `sudo ls -lh "$(docker inspect --format '{{.LogPath}}' web)"`

- Truncate without restarting (don't `rm` — daemon keeps FD open):
  `sudo truncate -s 0 "$(docker inspect --format '{{.LogPath}}' web)"`

## Remove specific resources

- All stopped:
  `docker rm $(docker ps -aq -f status=exited)`

- All (force-stops running):
  `docker rm -f $(docker ps -aq)`

- All images:
  `docker rmi $(docker images -q)`

- All volumes (skips in-use):
  `docker volume rm $(docker volume ls -q)`

## Reclaim from a specific image

- Containers using image:
  `docker ps -a --filter "ancestor=postgres:15"`

- Remove every tag of one repo:
  `docker images "myapp" -q | xargs -r docker rmi -f`

## Where disk goes

```
/var/lib/docker/
├── containers/    # per-container metadata, logs, configs
├── image/         # image metadata
├── overlay2/      # image layers + writable container layers (big)
├── volumes/       # named volumes' data
├── network/       # network state
└── buildkit/      # build cache
```

- Check size:
  `sudo du -sh /var/lib/docker/*`

> Never delete files directly — go through `docker` commands. State files in `containers/` and `image/` get out of sync otherwise.

## Scheduled cleanup

Weekly cron entry, prune images older than 168h:
```
0 4 * * 0 docker system prune -af --filter "until=168h" >/dev/null 2>&1
```

## Quick reference

| Command | Effect |
|---------|--------|
| `docker system df` | usage summary |
| `docker system df -v` | per-resource breakdown |
| `docker system prune` | stopped/unused nets/dangling/cache |
| `docker system prune -a` | + all unused images |
| `docker system prune -a --volumes` | + unused volumes (destructive) |
| `docker container prune` | stopped containers |
| `docker image prune [-a]` | dangling / all unused |
| `docker volume prune [-a]` | unused volumes |
| `docker network prune` | unused networks |
| `docker builder prune [-a]` | build cache |
