---
title: "Docker security and rootless"
date: 2026-05-23
tags: ["docker", "security", "rootless"]
source: doc/pages/docker/security-rootless.md
source_sha: e11c8d5e648a
---

> Daemon security model, rootless setup, unprivileged containers, capabilities, hardening.

## Why "docker group = root"

- Daemon runs as root (needs namespaces/cgroups/network setup).
- Socket `/var/run/docker.sock` is `root:docker` — group membership = API access to root daemon.
- API can be told "bind-mount `/` as RW" — escalation to root.

Demo (don't do on shared machines):
```
docker run --rm -v /:/host alpine cat /host/etc/shadow
```

Mitigations:
1. Don't add untrusted users to the `docker` group.
2. Use rootless Docker (below).
3. Use `sudo docker ...` instead of group membership.

## Rootless Docker

Daemon runs as your unprivileged user in a user namespace. If a container escapes, attacker only has your user's privileges, not root.

### Install on Arch

- AUR package:
  `yay -S docker-rootless-extras`

- Optional plugins:
  `sudo pacman -S docker-buildx docker-compose`

### One-time setup (per user, NOT root)

- Setup:
  `dockerd-rootless-setuptool.sh install`

- Enable + start at login:
  `systemctl --user enable --now docker`

- Point CLI at rootless socket:
  ```
  echo 'export DOCKER_HOST=unix:///run/user/'$(id -u)'/docker.sock' >> ~/.bashrc
  source ~/.bashrc
  ```

- Verify:
  `docker info | grep -i rootless`
  `docker run --rm hello-world`

### Limitations

- Ports < 1024 need `--cap-add NET_BIND_SERVICE` + slirp4netns, or `sysctl net.ipv4.ip_unprivileged_port_start=0`.
- `--network host` doesn't share host stack (uses user-namespaced network).
- Some FS ops slower (overlay2 over fuse-overlayfs).
- Cgroups v1 + rootless unsupported (modern distros use v2).

## Run unprivileged inside containers

### USER in Dockerfile

```dockerfile
FROM python:3.12-slim
RUN useradd --create-home --uid 1000 appuser
WORKDIR /home/appuser/app
COPY --chown=appuser . .
USER appuser
CMD ["python", "main.py"]
```

`USER` only affects subsequent instructions — do `apt install` and file setup first.

### --user at run time

- Match host UID/GID (bind mounts):
  `docker run --rm -v "$(pwd)":/work -w /work -u "$(id -u):$(id -g)" alpine sh`

- Numeric UID even if missing from `/etc/passwd`:
  `docker run --rm -u 1000:1000 alpine id`

### Read-only rootfs

- Read-only + tmpfs for writable paths:
  ```
  docker run --rm \
    --read-only \
    --tmpfs /tmp \
    --tmpfs /run \
    nginx
  ```

## Capabilities

- Drop all (ping fails — needs NET_RAW):
  `docker run --rm --cap-drop ALL alpine ping 8.8.8.8`

- Drop all, add back one:
  `docker run --rm --cap-drop ALL --cap-add NET_RAW alpine ping 8.8.8.8`

- Web server pattern:
  `docker run --rm --cap-drop ALL --cap-add NET_BIND_SERVICE nginx`

- Block setuid escalation:
  ```
  docker run --rm \
    --cap-drop ALL \
    --cap-add NET_BIND_SERVICE \
    --security-opt no-new-privileges \
    nginx
  ```

## seccomp / AppArmor / SELinux

- Default seccomp blocks ~50 syscalls.
- Ubuntu/Debian auto-apply AppArmor `docker-default`.
- Fedora/RHEL confine via SELinux `container_t`.

Relax for special cases only:
```
docker run --rm \
  --security-opt seccomp=unconfined \
  --cap-add SYS_PTRACE \
  alpine strace -e openat ls
```

## Image trust

- Prefer official images (`library/postgres`, …).
- Pin to digests in prod: `postgres@sha256:abc...`.
- Scan:
  `docker scout cves myapp:1.0`
  `trivy image myapp:1.0`

- Watch for typosquatting (`dockerr/nginx` ≠ `nginx`).

## Secrets

Don't bake secrets into images — they end up in layers and history.

- Build-time (BuildKit `--secret`):
  ```
  DOCKER_BUILDKIT=1 docker build \
    --secret id=npmrc,src=$HOME/.npmrc \
    -t myapp .
  ```
  Dockerfile: `RUN --mount=type=secret,id=npmrc,target=/root/.npmrc npm ci`

- Runtime: pass via env vars, files, or secret manager mounted as tmpfs. Don't `COPY` into image.

## Hardening checklist

- [ ] Non-root user inside container (`USER` or `--user`)
- [ ] `--read-only` rootfs + tmpfs for writable paths
- [ ] `--cap-drop ALL` + only needed caps added back
- [ ] `--security-opt no-new-privileges`
- [ ] Resource limits — `--memory`, `--cpus`, `--pids-limit`
- [ ] Bind to `127.0.0.1` for non-public services
- [ ] User-defined network
- [ ] Pin base images to digest
- [ ] `HEALTHCHECK`
- [ ] Rotate registry credentials; short-lived CI tokens
- [ ] Run rootless Docker if not on a multi-user host

## Quick reference

| Goal | Mechanism |
|------|-----------|
| daemon unprivileged | rootless Docker (`dockerd-rootless-setuptool.sh install`) |
| process not root | `USER` in Dockerfile or `--user UID:GID` |
| read-only fs | `--read-only --tmpfs /tmp` |
| minimal caps | `--cap-drop ALL --cap-add NEEDED_CAP` |
| block setuid | `--security-opt no-new-privileges` |
| build-time secrets | BuildKit `--secret` + `RUN --mount=type=secret,...` |
| vuln scan | `docker scout cves IMAGE` / `trivy image IMAGE` |
| immutable digest | `image@sha256:...` |
