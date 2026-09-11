---
title: "Docker networking"
date: 2026-05-23
tags: ["docker", "networking", "ports"]
source: doc/pages/docker/networking.md
source_sha: 61c7a15f0b27
---

> Network drivers, user-defined bridges, port publishing, container-to-container, diagnostics.

## Drivers

| Driver | What | When |
|--------|------|------|
| `bridge` (default) | private L2, NAT outbound | default for everything (user-defined recommended) |
| `host` | shares host stack, no isolation | raw performance, listen on host port without `-p` (Linux only) |
| `none` | no interfaces | sandbox, offline jobs |
| `overlay` | multi-host L2 | Swarm only |
| `macvlan` | own MAC on physical LAN | rare |

## Default bridge

When started without `--network`, containers attach to the default `bridge` network. **Containers on the default bridge can't resolve each other by name** — only by IP. Use a user-defined bridge instead.

## User-defined networks

- Create:
  `docker network create appnet`

- With options:
  ```
  docker network create \
    --driver bridge \
    --subnet 172.28.0.0/16 \
    --gateway 172.28.0.1 \
    appnet
  ```

- List:
  `docker network ls`

- Inspect (attached containers, IPAM):
  `docker network inspect appnet`

- Attach a running container:
  `docker network connect appnet web`

- Detach:
  `docker network disconnect appnet web`

- Remove (must have no containers):
  `docker network rm appnet`

- Cleanup unused:
  `docker network prune`

- Use at run:
  `docker run -d --name db --network appnet -e POSTGRES_PASSWORD=dev postgres:16`

Inside containers on `appnet`, `db` resolves to the container's IP via embedded DNS.

## Port publishing

- All host interfaces:
  `docker run -p 8080:80 nginx`

- Localhost only (not LAN-accessible):
  `docker run -p 127.0.0.1:8080:80 nginx`

- Specific interface:
  `docker run -p 192.168.1.10:8080:80 nginx`

- UDP (default is TCP):
  `docker run -p 53:53/udp coredns/coredns`

- Random free host port:
  `docker run -p 80 nginx`
  `docker port <container> 80`     # ask what it picked

- Publish all `EXPOSE`'d ports to random:
  `docker run -P nginx`

> **Warning:** `-p 8080:80` binds **all** interfaces — LAN-reachable. Bind to `127.0.0.1` for local-only.
> Docker on Linux inserts iptables rules directly and bypasses the host firewall (`ufw deny 8080` will NOT block a published port).

`EXPOSE` in Dockerfile is documentation only — still need `-p` at runtime. `-P` (capital) publishes all `EXPOSE`'d ports to random host ports.

## Container-to-container

```
docker network create appnet

docker run -d \
  --name db \
  --network appnet \
  -e POSTGRES_USER=app \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=appdb \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16

docker run -d \
  --name web \
  --network appnet \
  -p 8080:8080 \
  -e DATABASE_URL="postgres://app:secret@db:5432/appdb" \
  myapp:1.0
```

App uses `db` (container name) as the hostname. DB has no `-p` — only the app reaches it. For >2 services, switch to Compose.

## Host mode

- No NAT, no veth pair — container uses host stack directly:
  `docker run -d --network host nginx`

`-p` has no effect; container listens on host ports directly. Linux only (on Mac/Windows still goes through Linux VM).

## None mode

- Only `lo` interface:
  `docker run --rm --network none alpine ip addr`

## Diagnostics

- Alpine on same network:
  `docker run --rm -it --network appnet alpine sh`
  ```
  ping db
  nslookup db
  nc -zv db 5432
  ```

- Inside an existing container:
  `docker exec -it web sh`
  `nslookup db`
  `curl -v http://db:5432`

- All attached containers + IPs:
  `docker network inspect appnet`

## Quick reference

| Goal | Command |
|------|---------|
| create bridge | `docker network create NAME` |
| list | `docker network ls` |
| inspect | `docker network inspect NAME` |
| attach at start | `docker run --network NAME ...` |
| attach later | `docker network connect NAME CONTAINER` |
| disconnect | `docker network disconnect NAME CONTAINER` |
| remove | `docker network rm NAME` |
| cleanup | `docker network prune` |
| publish port | `-p [HOST_IP:]HOST:CONTAINER[/PROTO]` |
| random host port | `-p CONTAINER` |
| publish all EXPOSEd | `-P` |
| show published | `docker port CONTAINER` |
| host net | `--network host` |
| no net | `--network none` |
