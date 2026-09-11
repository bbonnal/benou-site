---
title: "systemd"
date: 2026-05-23
tags: ["system", "systemd", "units"]
source: doc/pages/system/systemd.md
source_sha: 9e37d62e2f86
---

> systemctl, unit files, timers, targets. For journalctl see `journalctl`.

## Service management

- Start / stop / restart:
  ```
  sudo systemctl start nginx
  sudo systemctl stop nginx
  sudo systemctl restart nginx
  ```

- Reload config (no restart):
  `sudo systemctl reload nginx`

- Enable at boot:
  `sudo systemctl enable nginx`

- Enable + start now:
  `sudo systemctl enable --now nginx`

- Disable / disable + stop:
  `sudo systemctl disable nginx` / `--now`

- Mask (block any start):
  `sudo systemctl mask nginx` / `unmask`

- Status:
  `systemctl status nginx`

- Quick checks (exit codes):
  ```
  systemctl is-active nginx
  systemctl is-enabled nginx
  systemctl is-failed nginx
  ```

- After editing unit files:
  `sudo systemctl daemon-reload`

- Heavy re-exec:
  `sudo systemctl daemon-reexec`

## List / inspect

- Running services:
  `systemctl list-units --type=service`

- All (incl. inactive):
  `systemctl list-units --type=service --all`

- Failed:
  `systemctl --failed`

- Enabled unit files:
  `systemctl list-unit-files --type=service --state=enabled`

- All unit files:
  `systemctl list-unit-files`

- Timers (next/last fire):
  `systemctl list-timers --all`

- Sockets:
  `systemctl list-sockets`

- Unit file contents:
  `systemctl cat nginx.service`

- All properties:
  `systemctl show nginx.service`

- Specific property:
  `systemctl show nginx.service -p MainPID`

- Dependencies:
  `systemctl list-dependencies nginx.service`

- Reverse dependencies:
  `systemctl list-dependencies --reverse nginx.service`

## Edit units

- Drop-in override (preferred):
  `sudo systemctl edit nginx.service`

- Full copy:
  `sudo systemctl edit --full nginx.service`

> Package-provided units live in `/usr/lib/systemd/system/` (don't edit). Admin overrides + custom go in `/etc/systemd/system/`.

## Writing a service unit

`/etc/systemd/system/myapp.service`:

```ini
[Unit]
Description=My Application
After=network.target
Wants=network.target

[Service]
Type=simple
User=myapp
Group=myapp
WorkingDirectory=/opt/myapp
ExecStart=/opt/myapp/bin/start
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

# Hardening
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
ReadWritePaths=/opt/myapp/data

[Install]
WantedBy=multi-user.target
```

### Service Type

| Type | Meaning |
|------|---------|
| `simple` | default; `ExecStart` is the main process |
| `exec` | like `simple` but ready only after binary starts |
| `forking` | parent forks then exits; set `PIDFile=` |
| `oneshot` | runs to completion; use `RemainAfterExit=yes` to keep active |
| `notify` | service signals readiness via `sd_notify()` |
| `idle` | like simple, delayed until all jobs dispatched |

### Restart policy

| Policy | Restart on… |
|--------|-------------|
| `no` | never (default) |
| `always` | any exit |
| `on-success` | exit 0 |
| `on-failure` | non-zero / signal / timeout / watchdog |
| `on-abnormal` | signal / timeout / watchdog |
| `on-abort` | signal only |

## Timer units

Timer + service share name (without extension). Timer triggers service.

`/etc/systemd/system/backup.timer`:
```ini
[Unit]
Description=Daily backup at 2am

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
```

`/etc/systemd/system/backup.service`:
```ini
[Unit]
Description=Backup job

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
```

- Enable timer:
  `sudo systemctl enable --now backup.timer`

- List active timers:
  `systemctl list-timers`

- Manually run associated service (test):
  `sudo systemctl start backup.service`

### OnCalendar

Format: `DayOfWeek Year-Month-Day Hour:Minute:Second`. `*` = any.

- Test an expression:
  `systemd-analyze calendar "Mon *-*-* 08:00:00"`
  `systemd-analyze calendar "hourly"`
  `systemd-analyze calendar "*-*-01 00:00:00"`

| Expression | Meaning |
|------------|---------|
| `minutely` | every minute |
| `hourly` | every hour |
| `daily` | midnight every day |
| `weekly` | Monday midnight |
| `monthly` | 1st of every month |
| `*-*-* *:00:00` | every hour |
| `Mon,Fri *-*-* 18:00:00` | Mon+Fri 18:00 |
| `*-*-01 02:00:00` | 1st @02:00 |
| `*-01,07-01 00:00:00` | Jan 1 + Jul 1 |

### Monotonic timers

```
OnBootSec=5min          # 5 min after boot
OnUnitActiveSec=1h      # 1 hour after last active
OnStartupSec=10min      # 10 min after systemd start
```

## Targets

- Current default:
  `systemctl get-default`

- Set default:
  `sudo systemctl set-default multi-user.target`
  `sudo systemctl set-default graphical.target`

- Switch now:
  `sudo systemctl isolate multi-user.target`
  `sudo systemctl isolate rescue.target`

| Target | Meaning |
|--------|---------|
| `poweroff.target` | shutdown |
| `rescue.target` | single-user, root shell |
| `multi-user.target` | no GUI |
| `graphical.target` | with GUI |
| `reboot.target` | reboot |
| `emergency.target` | even fewer services than rescue |

## Transient units (systemd-run)

- One-shot managed unit:
  `sudo systemd-run --unit=my-task /usr/local/bin/task.sh`

- As a user:
  `sudo systemd-run --uid=myuser /usr/local/bin/task.sh`

- One-off timer (30 min from now):
  `sudo systemd-run --on-active=30min /usr/local/bin/task.sh`

- Scope with limits:
  `sudo systemd-run --scope -p MemoryMax=500M /usr/local/bin/heavy-process`

## Environment

- Show manager environment:
  `systemctl show-environment`

- Set:
  `sudo systemctl set-environment MY_VAR=value`

## Verify / audit

- Validate unit file syntax:
  `systemd-analyze verify /etc/systemd/system/myapp.service`

- All unit file paths:
  `systemd-analyze unit-paths`

- Security score:
  `systemd-analyze security nginx.service`
