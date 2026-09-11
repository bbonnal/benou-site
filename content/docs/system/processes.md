---
title: "Processes"
date: 2026-05-23
tags: ["system", "processes", "signals"]
source: doc/pages/system/processes.md
source_sha: a8b09472064a
---

> ps, pstree, pgrep, kill/signals, nice/renice, job control, cgroups, ulimit, top/htop/btop.

## ps

- All processes (BSD style):
  `ps aux`

- All processes (POSIX style):
  `ps -ef`

- Tree view:
  `ps auxf` / `ps -ejH`

- By user:
  `ps -u jo`

- By name (exact):
  `ps -C nginx`

- By PID with custom columns:
  `ps -p 1234 -o pid,ppid,user,%cpu,%mem,stat,start,time,comm`

- Custom columns + sort (desc by mem):
  `ps -eo pid,ppid,user,%cpu,%mem,comm --sort=-%mem | head -20`

- Top CPU:
  `ps aux --sort=-%cpu | head -20`

- All threads:
  `ps -eLf`

- Threads for one process:
  `ps -T -p 1234`

## pstree

- Full tree:
  `pstree`

- Include PIDs:
  `pstree -p`

- Show users:
  `pstree -u`

- Command-line args:
  `pstree -a`

- Tree rooted at PID:
  `pstree -p 1234`

## Finding processes

- By name (PID only):
  `pgrep nginx`

- Match full command line:
  `pgrep -f "python script.py"`

- With command line:
  `pgrep -a nginx`

- With name:
  `pgrep -l nginx`

- By user:
  `pgrep -u jo`

- Count matches:
  `pgrep -c nginx`

- What's using a port:
  `ss -tlnp sport = :80` / `fuser 80/tcp`

- What's using a file:
  `fuser /var/log/syslog` / `lsof /var/log/syslog`

- Open files of process:
  `lsof -p 1234`

- Network sockets:
  `lsof -i` / `lsof -i :80` / `lsof -i tcp`

## Kill

- Graceful (SIGTERM):
  `kill 1234`

- Force (SIGKILL):
  `kill -9 1234`

- Reload config (SIGHUP):
  `kill -HUP 1234`

- By exact name:
  `killall nginx`

- By pattern (full command):
  `pkill -f "python script.py"`

- All processes of a user:
  `pkill -u baduser`

- Kill on port:
  `fuser -k 80/tcp`

- Kill process group (negative PID):
  `kill -TERM -1234`

## Signals

| Signal | # | Default | Use |
|--------|---|---------|-----|
| `SIGHUP` | 1 | terminate | reload config / terminal hangup |
| `SIGINT` | 2 | terminate | Ctrl+C |
| `SIGQUIT` | 3 | core dump | Ctrl+\\ |
| `SIGKILL` | 9 | terminate | force kill (uncatchable) |
| `SIGTERM` | 15 | terminate | graceful (default `kill`) |
| `SIGSTOP` | 19 | stop | pause (uncatchable) |
| `SIGCONT` | 18 | continue | resume |
| `SIGUSR1` | 10 | terminate | app-specific |
| `SIGUSR2` | 12 | terminate | app-specific |

- List signals:
  `kill -l`

- Send by name or number:
  `kill -SIGTERM 1234` / `kill -15 1234`

- Trap in shell script:
  `trap 'echo "Caught SIGINT"; cleanup; exit' INT TERM`

## nice / renice

Range -20 (highest) to 19 (lowest). Default 0. Negative needs root.

- Start lower priority:
  `nice -n 10 tar czf backup.tar.gz /data`

- Start higher (root):
  `sudo nice -n -5 important-process`

- Change running process:
  `renice 10 -p 1234`

- For all of a user:
  `sudo renice 15 -u baduser`

- For a process group:
  `sudo renice 10 -g 5678`

- Check value:
  `ps -o pid,ni,comm -p 1234`

## Job control

- Background:
  `long-command &`

- List jobs:
  `jobs` / `jobs -l` (with PID)

- Suspend foreground:
  `Ctrl+Z`

- Resume in background:
  `bg` / `bg %2`

- Resume in foreground:
  `fg` / `fg %1`

- Wait for jobs:
  `wait` / `wait %1` / `wait 1234`

- Detach from shell:
  `disown %1` / `disown -a`

- Immune to hangup, output redirected:
  `nohup long-command > output.log 2>&1 &`

- Fully detached (new session):
  `setsid long-command &`

## cgroups (systemd)

- View hierarchy:
  `systemd-cgls`

- Like top for cgroups:
  `systemd-cgtop`

- Set memory limit on service:
  `sudo systemctl set-property nginx.service MemoryMax=512M`

- Set CPU quota (100% = 1 core):
  `sudo systemctl set-property myapp.service CPUQuota=50%`

- Persistent via override (`systemctl edit myapp.service`):
  ```
  [Service]
  MemoryMax=1G
  MemoryHigh=800M
  CPUQuota=200%
  TasksMax=100
  IOWeight=50
  ```

- Transient scope with limits:
  `sudo systemd-run --scope -p MemoryMax=256M -p CPUQuota=50% ./heavy-task`

- Current cgroup of process:
  `cat /proc/1234/cgroup`

- Available controllers:
  `cat /sys/fs/cgroup/cgroup.controllers`

## ulimit

- All limits:
  `ulimit -a`

- Open files:
  `ulimit -n`

- Max user processes:
  `ulimit -u`

- Virtual memory:
  `ulimit -v`

- Stack:
  `ulimit -s`

- Limits of running process:
  `cat /proc/1234/limits`

- Set soft (session):
  `ulimit -n 65535`

- Set hard (root):
  `ulimit -Hn 65535`

- Persistent (`/etc/security/limits.conf`):
  ```
  jo           soft  nofile  65535
  jo           hard  nofile  65535
  @developers  soft  nproc   4096
  ```

- Systemd service limit (in unit):
  ```
  [Service]
  LimitNOFILE=65535
  LimitNPROC=4096
  ```

## Real-time monitors

- top — classic:
  `top` (M=sort mem, P=sort cpu, k=kill, r=renice, 1=per-CPU, c=full cmd)

- htop — improved:
  `htop` (F5 tree, F6 sort, F9 kill, F2 setup)

- btop — modern:
  `btop`

- iotop — per-process disk I/O:
  `sudo iotop -o`

- iftop — per-connection bandwidth:
  `sudo iftop -i enp0s3`

- nethogs — per-process bandwidth:
  `sudo nethogs enp0s3`
