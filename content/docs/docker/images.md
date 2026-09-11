---
title: "Docker images"
date: 2026-05-23
tags: ["docker", "images", "registry"]
source: doc/pages/docker/images.md
source_sha: 755f46e9774e
---

> Pull, list, inspect, retag, remove. Save/load as tarballs.

## Image name anatomy

```
[REGISTRY/[NAMESPACE/]]REPOSITORY[:TAG][@DIGEST]
```

| Part | Example | Default |
|------|---------|---------|
| Registry | `ghcr.io` | `docker.io` |
| Namespace | `myorg` | `library` (Docker Hub officials only) |
| Repository | `postgres` | required |
| Tag | `:16` | `:latest` |
| Digest | `@sha256:abc…` | none |

`postgres:16` ≡ `docker.io/library/postgres:16`. Tags are mutable — use digest form for byte-stable references.

## Pull

- Latest:
  `docker pull nginx`

- Specific tag:
  `docker pull postgres:16`

- Other registry:
  `docker pull ghcr.io/myorg/myapp:1.2`

- Specific platform:
  `docker pull --platform linux/amd64 alpine:3.20`

- All tags (rarely useful):
  `docker pull --all-tags nginx`

> Anonymous Docker Hub pulls are rate-limited (100/6h per IP). `docker login` raises the quota.

## List local images

- All:
  `docker images`

- One repo:
  `docker images postgres`

- IDs only:
  `docker images -q`

- Include dangling:
  `docker images -a`

- Predicate filter:
  `docker images --filter "dangling=true"`
  `docker images --filter "since=postgres:15"`

- Custom format:
  `docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"`

## Inspect

- Full JSON:
  `docker inspect postgres:16`

- Specific field:
  `docker inspect --format '{{.Config.Cmd}}' postgres:16`
  `docker inspect --format '{{.Config.Env}}' postgres:16`
  `docker inspect --format '{{.Config.ExposedPorts}}' postgres:16`

- Layer-by-layer build history:
  `docker history postgres:16`

- Full command, no truncation:
  `docker history --no-trunc postgres:16`

## Search Docker Hub

- Keyword:
  `docker search nginx`

- Limit:
  `docker search --limit 5 redis`

- Officials only:
  `docker search --filter "is-official=true" python`

## Retag

- Alias to new name:
  `docker tag myapp:dev myapp:1.0.0`

- Tag for push to GHCR:
  `docker tag myapp:1.0.0 ghcr.io/myorg/myapp:1.0.0`

- Tag with both version and latest:
  `docker tag myapp:1.0.0 myapp:latest`

## Remove

- By name+tag:
  `docker rmi postgres:15`

- By ID:
  `docker rmi 9d6a8c1f0d3e`

- Force (containers must be stopped):
  `docker rmi -f myapp:dev`

- Dangling:
  `docker image prune`

- All unused (dangling + tagged but unused):
  `docker image prune -a`

## Save / load

- Save image to tar:
  `docker save -o myapp-1.0.0.tar myapp:1.0.0`

- Load from tar:
  `docker load -i myapp-1.0.0.tar`

- Save + gzip:
  `docker save myapp:1.0.0 | gzip > myapp-1.0.0.tar.gz`

> Use `save`/`load` for **images** (preserves metadata). `export`/`import` operate on container filesystems and lose `CMD`/`ENV`.

## Quick reference

| Command | Purpose |
|---------|---------|
| `docker pull NAME[:TAG]` | download from registry |
| `docker images [REPO]` | list local |
| `docker inspect NAME` | metadata |
| `docker history NAME` | per-layer build history |
| `docker search TERM` | search Hub |
| `docker tag SRC TARGET` | additional name |
| `docker rmi NAME` | delete |
| `docker image prune [-a]` | bulk cleanup |
| `docker save -o FILE NAME` | export to tar |
| `docker load -i FILE` | import from tar |
