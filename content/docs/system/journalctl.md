---
title: "journalctl"
date: 2026-05-23
tags: ["system", "logs", "journald"]
source: doc/pages/system/journalctl.md
source_sha: 275cf8fcf501
---

> Reading system logs with journalctl and the kernel ring buffer (dmesg).

## Common invocations

- All logs for current boot:
  `journalctl -b`

- Logs from previous boot:
  `journalctl -b -1`

- List boots with timestamps:
  `journalctl --list-boots`

- Only errors and above:
  `journalctl -b -p err`

- Follow live (like tail -f):
  `journalctl -f`

- Recent logs (last 10 minutes):
  `journalctl --since "10 min ago"`

- Time range:
  `journalctl --since "2025-01-01" --until "2025-01-02"`

- Jump to end:
  `journalctl -e`

- Last N lines:
  `journalctl -n 50`

- Newest first:
  `journalctl -r`

## Filter by unit

- Specific service:
  `journalctl -u NetworkManager`

- Follow one service:
  `journalctl -fu nginx`

- User service:
  `journalctl --user -u wireplumber -n 50 --no-pager`

## Filter by priority

`-p` shows the specified level **and above** (more severe).

| Level | Name |
|-------|------|
| 0 | `emerg` |
| 1 | `alert` |
| 2 | `crit` |
| 3 | `err` |
| 4 | `warning` |
| 5 | `notice` |
| 6 | `info` |
| 7 | `debug` |

- Errors and above:
  `journalctl -p err`

- Priority range:
  `journalctl -p err..crit`

## Advanced filters

- Kernel messages only:
  `journalctl -k`

- By PID:
  `journalctl _PID=1234`

- By UID:
  `journalctl _UID=1000`

- By binary path:
  `journalctl /usr/bin/nginx`

- By transport (kernel/audit):
  `journalctl _TRANSPORT=kernel`

- Combine filters (AND):
  `journalctl -b -p err _TRANSPORT=kernel`

## Output formats

- Pretty JSON:
  `journalctl -o json-pretty`

- ISO timestamps:
  `journalctl -o short-iso`

- Message only:
  `journalctl -o cat`

- All fields, verbose:
  `journalctl -o verbose`

## Filter by keyword

- Pipe to grep:
  `journalctl -b | grep -i hdmi`
  `journalctl -b | grep amdgpu`

- Open in nvim for searching:
  `journalctl --since "15 min ago" | nvim`

## Useful one-liners

- Resume from suspend:
  `journalctl -b -1 | grep -i resume`

- Lid events:
  `journalctl -f | grep -i lid`

- Suspend/hibernate image:
  `journalctl -b | grep -i "PM: Image"`

- Kernel messages (dmesg-style, with color/highlight):
  `sudo journalctl -kg`

## Journal disk management

- Total disk usage:
  `journalctl --disk-usage`

- Rotate now:
  `sudo journalctl --rotate`

- Vacuum by time:
  `sudo journalctl --vacuum-time=7d`

- Vacuum by size:
  `sudo journalctl --vacuum-size=500M`

- Vacuum by file count:
  `sudo journalctl --vacuum-files=5`

- Verify integrity:
  `journalctl --verify`

## journald configuration

File: `/etc/systemd/journald.conf`

```
[Journal]
Storage=persistent
Compress=yes
SystemMaxUse=500M
SystemMaxFileSize=50M
MaxRetentionSec=1month
MaxFileSec=1week
```

Apply with `sudo systemctl restart systemd-journald`.

## dmesg (kernel ring buffer)

- Show kernel messages:
  `dmesg`

- Human-readable timestamps:
  `dmesg -T`

- Color output:
  `dmesg --color=always`

- Follow live:
  `dmesg -w`

- Filter by facility:
  `dmesg -f kern`

- Filter by level:
  `dmesg -l err,warn`

- Common searches:
  ```
  dmesg | grep -i usb
  dmesg | grep -i "nvidia\|amd\|gpu"
  dmesg | grep -i oom
  dmesg | grep -i "error\|fail"
  ```

- Clear ring buffer:
  `sudo dmesg -C`

## Boot analysis

- Total boot time breakdown:
  `systemd-analyze`

- Per-unit boot times:
  `systemd-analyze blame`

- Critical chain:
  `systemd-analyze critical-chain`

- Per-unit critical chain:
  `systemd-analyze critical-chain nginx.service`

- SVG visualization:
  `systemd-analyze plot > boot-chart.svg`
