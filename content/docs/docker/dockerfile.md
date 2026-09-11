---
title: "Dockerfile"
date: 2026-05-23
tags: ["docker", "dockerfile", "build"]
source: doc/pages/docker/dockerfile.md
source_sha: b1cf99df4112
---

> Building images: instructions, .dockerignore, layer caching, ARG vs ENV, multi-stage.

## Build

- From current dir:
  `docker build -t myapp:1.0 .`

- Custom Dockerfile location:
  `docker build -t myapp:1.0 -f deploy/Dockerfile .`

- No cache:
  `docker build --no-cache -t myapp:1.0 .`

The `.` is the **build context** — sent to the daemon. Always use a focused subdir + `.dockerignore`.

## Instructions

| Instruction | Purpose |
|-------------|---------|
| `FROM` | base image (first non-comment) |
| `RUN` | execute at build time, commit layer |
| `COPY` | copy from build context into image |
| `ADD` | like `COPY` + URLs/auto-extract tar. Prefer `COPY`. |
| `WORKDIR` | working dir (created if absent) |
| `ENV` | env var (build + runtime) |
| `ARG` | build-time-only variable |
| `CMD` | default command (overridable) |
| `ENTRYPOINT` | fixed command (run args appended) |
| `EXPOSE` | doc only — still needs `-p` |
| `USER` | drop privileges |
| `VOLUME` | declare volume mount point |
| `LABEL` | metadata |
| `HEALTHCHECK` | periodic health test |
| `STOPSIGNAL` | signal on `docker stop` |

## CMD vs ENTRYPOINT

- **`CMD` alone**: default command, fully overridable.
- **`ENTRYPOINT` alone**: fixed command, run args appended.
- **Both**: ENTRYPOINT is the program, CMD is default args.
- **Prefer exec form** (`["cmd", "arg"]`) over shell form (`cmd arg`) — shell form wraps in `/bin/sh -c` and signals don't reach your app.

## .dockerignore

```
.git
.gitignore
.dockerignore
Dockerfile
README.md

bin/
obj/
build/
dist/
target/
*.log

node_modules/
__pycache__/
.venv/

.idea/
.vscode/
.DS_Store

.env
*.pem
*.key
```

## Layer caching

Order matters. Copy dependency manifests first, install, **then** copy source — that way unrelated source changes don't bust the install layer.

```dockerfile
# GOOD
FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY . .
CMD ["node", "server.js"]
```

Same pattern for every ecosystem:
- Python: `requirements.txt` → `pip install` → code
- Go: `go.mod`/`go.sum` → `go mod download` → code
- .NET: `*.csproj` → `dotnet restore` → code

## ARG vs ENV

| | ARG | ENV |
|-|-----|-----|
| Build time | yes | yes |
| Runtime container env | **no** | yes |
| CLI override | `--build-arg KEY=VAL` | `-e KEY=VAL` |
| Persisted in image | name only | key + value |

Use `ARG` for build flags, version numbers, mirror URLs. Use `ENV` for runtime config. **Never use `ARG` for secrets** — value leaks into history.

```dockerfile
ARG NODE_VERSION=20
FROM node:${NODE_VERSION}-alpine

ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION}
LABEL org.opencontainers.image.version=${APP_VERSION}
```

```
docker build --build-arg NODE_VERSION=22 --build-arg APP_VERSION=1.2.3 -t myapp:1.2.3 .
```

## Multi-stage builds

Multiple `FROM`. Only last stage becomes final image; earlier stages referenced via `COPY --from=...`. Big SDK → tiny runtime image.

```dockerfile
# Stage 1: SDK
FROM golang:1.22 AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /out/myapp ./cmd/myapp

# Stage 2: runtime
FROM gcr.io/distroless/static:nonroot
COPY --from=builder /out/myapp /myapp
ENTRYPOINT ["/myapp"]
```

- Stop at specific stage:
  `docker build --target builder -t myapp:builder .`

## Example: Python web service

```dockerfile
FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd --create-home --uid 1000 appuser
USER appuser

ENV PORT=8000
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD curl -f http://localhost:${PORT}/healthz || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Example: multi-stage .NET app

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY ["src/MyApp.Api/MyApp.Api.csproj", "src/MyApp.Api/"]
COPY ["src/MyApp.Domain/MyApp.Domain.csproj", "src/MyApp.Domain/"]
RUN dotnet restore "src/MyApp.Api/MyApp.Api.csproj"

COPY . .
RUN dotnet publish "src/MyApp.Api/MyApp.Api.csproj" \
    -c Release \
    -o /app/publish \
    --no-restore \
    /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
USER app
ENV ASPNETCORE_URLS=http://+:8080 \
    ASPNETCORE_ENVIRONMENT=Production
EXPOSE 8080
ENTRYPOINT ["dotnet", "MyApp.Api.dll"]
```

Notes:
- .NET images on `mcr.microsoft.com/dotnet/...`, not Docker Hub.
- `aspnet:9.0` for web apps, `runtime:9.0` for console, `runtime-deps:9.0` for self-contained/AOT.

## Tagging conventions

- Always tag with a version (never just `:latest`).
- Tag with both specific + moving: `myapp:1.2.3` AND `myapp:1.2`.
- Include git SHA: `myapp:1.2.3-abc1234`.
- Use digest pins (`myapp@sha256:...`) where byte stability matters.

```
docker build \
  -t myapp:1.2.3 \
  -t myapp:1.2 \
  -t myapp:latest \
  --label org.opencontainers.image.revision=$(git rev-parse HEAD) \
  .
```

## docker build options

| Option | Effect |
|--------|--------|
| `-t NAME[:TAG]` | tag (repeatable) |
| `-f FILE` | Dockerfile path |
| `--build-arg KEY=VAL` | set ARG |
| `--target STAGE` | stop at stage |
| `--platform P` | target platform (e.g. `linux/arm64`) |
| `--no-cache` | disable cache |
| `--pull` | always re-pull base |
| `--label K=V` | add label |
| `--progress=plain` | full output |
