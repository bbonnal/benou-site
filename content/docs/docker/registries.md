---
title: "Docker registries"
date: 2026-05-23
tags: ["docker", "registry", "ghcr"]
source: doc/pages/docker/registries.md
source_sha: 69c7c3c40748
---

> Docker Hub, GHCR, private registries, login, push, naming, self-hosted.

## Image name → registry

First segment of the image name decides the registry. Contains `.` or `:` → hostname; otherwise → Docker Hub.

| Image | Registry | Notes |
|-------|----------|-------|
| `nginx` | `docker.io` | implicit `library/` |
| `library/nginx` | `docker.io` | explicit |
| `myuser/myapp` | `docker.io` | user repo |
| `ghcr.io/myuser/myapp` | `ghcr.io` | GitHub |
| `gcr.io/project/myapp` | `gcr.io` | Google |
| `quay.io/org/myapp` | `quay.io` | Quay |
| `123…ecr.us-east-1.amazonaws.com/myapp` | AWS ECR | region URL |
| `registry.example.com:5000/myapp` | self | host + port |
| `localhost:5000/myapp` | self | local |

To push to a non-Hub registry, tag with the full path first.

## Docker Hub

- Login (use PAT, not password):
  `docker login`

- Tag local for Hub:
  `docker tag myapp:1.0 myuser/myapp:1.0`

- Push:
  `docker push myuser/myapp:1.0`

- Multiple tags:
  ```
  docker push myuser/myapp:1.0
  docker push myuser/myapp:latest
  ```

## GHCR (GitHub Container Registry)

Free, no anonymous rate limits, integrates with Actions. Auth via classic PAT with `write:packages` scope.

- Login:
  `echo "$GHCR_PAT" | docker login ghcr.io -u myuser --password-stdin`

- Tag (lowercase only):
  `docker tag myapp:1.0 ghcr.io/myuser/myapp:1.0`

- Push:
  `docker push ghcr.io/myuser/myapp:1.0`

By default a new GHCR package is **private**. Change visibility in GitHub UI.

OCI labels for discoverability:
```dockerfile
LABEL org.opencontainers.image.source=https://github.com/myuser/myapp
LABEL org.opencontainers.image.description="My application"
LABEL org.opencontainers.image.licenses=MIT
```

## Private registry

- Login:
  `docker login registry.example.com`
  `docker login registry.example.com:5000`

- Tag:
  `docker tag myapp:1.0 registry.example.com/team/myapp:1.0`

- Push:
  `docker push registry.example.com/team/myapp:1.0`

- Logout:
  `docker logout registry.example.com`

## Pulling private images

- Non-interactive (CI):
  `echo "$REGISTRY_PASSWORD" | docker login -u "$REGISTRY_USER" --password-stdin registry.example.com`

## docker login storage

Credentials cached in `~/.docker/config.json` (base64-encoded). To use a credential helper on Linux (`docker-credential-pass`):

```json
{
  "auths": {
    "ghcr.io": {},
    "docker.io": {}
  },
  "credsStore": "pass"
}
```

## Self-hosted registry

- Simple registry (no auth, no TLS — lab use only):
  ```
  docker run -d \
    --name registry \
    --restart unless-stopped \
    -p 5000:5000 \
    -v registry-data:/var/lib/registry \
    registry:2
  ```

- Tag + push:
  ```
  docker tag myapp:1.0 localhost:5000/myapp:1.0
  docker push localhost:5000/myapp:1.0
  docker pull localhost:5000/myapp:1.0
  ```

For real use: front with TLS reverse proxy + basic-auth or tokens.

## Inspect remote without pulling

- Old way (may need experimental):
  `docker manifest inspect nginx:1.27`

- Platforms:
  `docker manifest inspect --verbose nginx:1.27 | grep -i architecture`

- Modern (no experimental flag):
  `docker buildx imagetools inspect nginx:1.27`

## Tagging conventions

- Specific version + moving minor + latest + SHA:
  ```
  GIT_SHA=$(git rev-parse --short HEAD)
  VERSION=1.2.3

  docker build \
    -t ghcr.io/me/myapp:${VERSION} \
    -t ghcr.io/me/myapp:${VERSION%.*} \
    -t ghcr.io/me/myapp:latest \
    -t ghcr.io/me/myapp:sha-${GIT_SHA} \
    --label org.opencontainers.image.revision=${GIT_SHA} \
    --label org.opencontainers.image.version=${VERSION} \
    --label org.opencontainers.image.source=https://github.com/me/myapp \
    .

  docker push --all-tags ghcr.io/me/myapp
  ```

## Quick reference

| Goal | Command |
|------|---------|
| login Hub | `docker login` |
| login other | `docker login REGISTRY[:PORT]` |
| logout | `docker logout [REGISTRY]` |
| tag for push | `docker tag SRC REGISTRY/NS/REPO:TAG` |
| push | `docker push REGISTRY/NS/REPO:TAG` |
| push all tags | `docker push --all-tags REGISTRY/NS/REPO` |
| inspect remote | `docker buildx imagetools inspect IMAGE` |
| self-host | `docker run -d -p 5000:5000 registry:2` |
