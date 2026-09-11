---
title: "Docker installation"
date: 2026-05-23
tags: ["docker", "installation", "arch"]
source: doc/pages/docker/installation.md
source_sha: 6ca427257bb5
---

> Install Docker Engine on Arch, configure user access, verify, uninstall.

## Install

- Engine (brings in containerd + runc):
  `sudo pacman -S docker`

- Buildx + Compose plugins (optional):
  `sudo pacman -S docker-buildx docker-compose`

## Daemon

The `docker.service` is not started by default on Arch.

- Enable + start now:
  `sudo systemctl enable --now docker.service`

- Status:
  `sudo systemctl status docker.service`

## User access

You can keep using `sudo docker ...` or add your user to the `docker` group (root-equivalent — see `security-rootless`):

- Add to group:
  `sudo usermod -aG docker $USER`

- Refresh current shell (or log out + back in):
  `newgrp docker`

## Verify

- Versions:
  `docker version`

- Daemon info (storage/cgroup driver, kernel):
  `docker info`

- End-to-end test:
  `docker run --rm hello-world`

## Daemon config

`/etc/docker/daemon.json` (create if missing):

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "data-root": "/var/lib/docker"
}
```

- `log-opts` caps per-container log file size.
- `data-root` moves Docker's storage to another disk.

Apply with `sudo systemctl restart docker`.

## Uninstall

- Stop daemon:
  `sudo systemctl disable --now docker.service`

- Remove package(s):
  `sudo pacman -Rns docker docker-buildx docker-compose`

- (Optional) wipe data — destroys all images, containers, volumes:
  `sudo rm -rf /var/lib/docker /var/lib/containerd`

## Troubleshooting

| Symptom | Cause / fix |
|---------|-------------|
| `Cannot connect to the Docker daemon at unix:///var/run/docker.sock` | Daemon not running (`systemctl start docker`) or user not in `docker` group / didn't refresh shell. |
| `permission denied while trying to connect to the Docker daemon socket` | Group membership not active. `newgrp docker` or new terminal. |
| `Error response from daemon: pull access denied` | Wrong name/tag, or private image — see `registries`. |
| Daemon won't start, cgroup errors in journal | Old kernel / conflicting cgroup driver in `daemon.json`. Compare `docker info | grep -i cgroup` with systemd. |
