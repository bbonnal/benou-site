---
title: "Docker overview"
date: 2026-05-23
tags: ["docker", "concepts"]
source: doc/pages/docker/overview.md
source_sha: 5b94d5bd8c2f
---

> Mental model and vocabulary: images, containers, layers, registries, lifecycle.

## Why Docker

- **Reproducibility** — same image runs identically on laptop, CI, prod.
- **Isolation** — own filesystem + process namespace per container.
- **Distribution** — versioned artifacts in a registry (`docker pull org/app:2.3`).
- **Disposability** — throw away + recreate, don't patch in place.

## Containers vs VMs

- VM emulates whole machine (hypervisor + guest kernel + guest OS).
- Container shares host kernel; only packages user space (libs, binaries, config).
- Containers are smaller and faster but can't run a Linux container on Windows/macOS without a Linux VM (Docker Desktop provides this).

## Client–daemon model

- `dockerd` — long-running daemon, manages images/containers/networks/volumes via `containerd`/`runc`.
- `docker` — CLI that sends JSON to `dockerd` over `/var/run/docker.sock`.
- Membership in the `docker` group = root-equivalent on the host (see `security-rootless`).

- Socket location:
  `ls -l /var/run/docker.sock`

- Verify daemon reachable:
  `docker info`

## Core vocabulary

| Term | Meaning |
|------|---------|
| **Image** | read-only filesystem snapshot + metadata. Built from `Dockerfile` or pulled. Identified `name:tag`. |
| **Container** | a running (or stopped) image instance with a thin writable layer. Own PID/mounts/network. |
| **Layer** | image is stacked read-only layers (one per `RUN`/`COPY`/`ADD`). Content-addressed and cached. |
| **Tag** | mutable name pointer (`postgres:16`). `:latest` is not stable. |
| **Digest** | immutable SHA256 (`postgres@sha256:abc…`). Use for byte-for-byte reproducibility. |
| **Registry** | server hosting images (`docker.io`, `ghcr.io`, …). |
| **Repository** | named image collection on a registry, usually one app + many tags. |
| **Volume** | persistent storage managed by Docker, decoupled from container lifecycle. |
| **Bind mount** | host directory/file mounted into container. Docker doesn't manage the data. |
| **Network** | virtual L2 between containers. Default `bridge` + user-defined bridges most common. |
| **Build context** | directory passed to `docker build` (e.g. `.`). Minus `.dockerignore`, sent to daemon. |
| **Dockerfile** | text recipe for building an image. |

## Container lifecycle

```
            create              start             stop / exit
created  ────────►  created  ──────►  running  ─────────►  exited
                                       │   ▲                 │
                                  pause│   │unpause          │ rm
                                       ▼   │                 ▼
                                     paused                removed
```

- `docker run` = pull (if needed) + create + start [+ attach].
- `docker ps` = running; `docker ps -a` = all states (incl. exited).
- Stopped container keeps its writable layer until `docker rm`.

## How a run becomes a running container

`docker run -d --name pg -p 5432:5432 -e POSTGRES_PASSWORD=dev postgres:16`

1. Resolve image. If absent locally, daemon pulls from registry.
2. Create. Stack image layers + add writable top layer. Allocate network iface on default bridge, set port-forward rule, env vars.
3. Start. Daemon execs image `CMD`/`ENTRYPOINT` as PID 1 inside the container's namespaces. `-d` detaches the shell.
4. Cleanup. `docker stop pg` sends SIGTERM (then SIGKILL after grace). `docker rm pg` deletes writable layer.

## See also

| Topic | Page |
|-------|------|
| install | `installation` |
| pull / inspect images | `images` |
| run / stop / inspect containers | `containers` |
| build images | `dockerfile` |
| persist data | `volumes` |
| networks + ports | `networking` |
| multi-container | `compose` |
| push to registry | `registries` |
| free disk | `cleanup` |
| security + rootless | `security-rootless` |
