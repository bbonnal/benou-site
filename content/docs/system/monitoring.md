---
title: "Monitoring"
date: 2026-05-23
tags: ["system", "monitoring", "hardware"]
source: doc/pages/system/monitoring.md
source_sha: 009a9ab91e65
---

> vmstat, iostat, sar, hardware info, sensors, inotifywait, /proc and /sys.
> See also `journalctl` for log analysis and `processes` for top/htop/btop.

## vmstat

- Snapshot:
  `vmstat`

- Every 2 sec, 10 samples:
  `vmstat 2 10`

- Active/inactive memory:
  `vmstat -a`

- With timestamps:
  `vmstat -t 1`

- Disk stats:
  `vmstat -d`

- In MB:
  `vmstat -S M`

| Section | Field | Meaning |
|---------|-------|---------|
| procs | `r` | runnable (CPU-bound) |
| procs | `b` | blocked (I/O) |
| memory | `swpd` | swap used |
| memory | `free` | free RAM |
| memory | `buff/cache` | buffers/cache |
| swap | `si/so` | swap in/out — non-zero so → memory pressure |
| io | `bi/bo` | blocks in/out per sec |
| system | `in/cs` | interrupts / context switches |
| cpu | `us/sy/id` | user/system/idle |
| cpu | `wa` | I/O wait (high → disk bottleneck) |
| cpu | `st` | stolen (VM) |

## iostat

Install `sysstat`.

- Basic:
  `iostat`

- Extended every 2 sec:
  `iostat -x -t 2`

- Specific device:
  `iostat -x /dev/nvme0n1`

- MB/s:
  `iostat -m`

- CPU only / device only:
  `iostat -c` / `iostat -d`

### Extended fields (-x)

| Field | Meaning |
|-------|---------|
| `r/s`, `w/s` | reads/writes per sec |
| `rMB/s`, `wMB/s` | throughput |
| `await` | wait (queue+service) ms |
| `%util` | device utilization |

## sar

Install `sysstat` and enable the collector:
`sudo systemctl enable --now sysstat`

- CPU live:
  `sar -u 1 5`

- Memory:
  `sar -r 1 5`

- Disk:
  `sar -d 1 5`

- Network per-iface:
  `sar -n DEV 1 5`

- Sockets:
  `sar -n SOCK 1 5`

- Historical CPU from file:
  `sar -u -f /var/log/sa/sa13`

- Memory in window:
  `sar -r -s 08:00:00 -e 17:00:00`

## Hardware

- CPU summary:
  `lscpu`

- Per-core info:
  `cat /proc/cpuinfo`

- Core count:
  `nproc`

- Memory summary:
  `free -h`

- Detailed memory:
  `cat /proc/meminfo`

- PCI devices:
  `lspci` / `lspci -v` / `lspci -k`

- Find GPU:
  `lspci | grep -i vga`

- USB:
  `lsusb` / `lsusb -v` / `lsusb -t`

- BIOS/DMI:
  `sudo dmidecode`
  `sudo dmidecode -t memory`
  `sudo dmidecode -t bios`
  `sudo dmidecode -t system`

- Block devices + fs info:
  `lsblk -f`

- Disk model/firmware:
  `sudo hdparm -I /dev/sda`

- Sensors:
  ```
  sudo sensors-detect    # one-time
  sensors
  ```

- Battery:
  `upower -i /org/freedesktop/UPower/devices/battery_BAT0`
  `cat /sys/class/power_supply/BAT0/capacity`

- Kernel / OS:
  ```
  uname -a
  uname -r
  hostnamectl
  cat /etc/os-release
  uptime
  ```

## inotifywait

Install `inotify-tools`.

- Watch file (blocks):
  `inotifywait -m /path/to/file`

- Recursive directory:
  `inotifywait -mr /path/to/dir`

- Specific events:
  `inotifywait -m -e modify,create,delete /path/to/dir`

- Formatted with timestamps:
  `inotifywait -mr --format '%T %w%f %e' --timefmt '%F %T' /path/to/dir`

- Auto-rebuild on change:
  ```
  inotifywait -mr -e modify --include '\.py$' ./src | while read -r path event file; do
      echo "Change: $file"
      make build
  done
  ```

- One-shot:
  `inotifywait -e modify /etc/hosts && echo "changed"`

| Event | When |
|-------|------|
| `access` | file read |
| `modify` | content change |
| `attrib` | metadata change |
| `close_write` | RW file closed |
| `open` | file opened |
| `moved_to/from` | moved in/out of dir |
| `create` | created |
| `delete` | deleted |

## All-in-one monitors

- btop (recommended):
  `btop`

- glances (with web mode):
  `glances`

- dstat (one-line stats):
  `dstat -cdngy` (cpu, disk, net, page, sys)

## ncdu (interactive disk usage)

`ncdu /home`

## watch

- Repeat with highlight:
  `watch -d free -h`

- Socket stats every sec:
  `watch -n 1 "ss -s"`

## /proc & /sys

System-wide:

```
cat /proc/cpuinfo
cat /proc/loadavg
cat /proc/meminfo
cat /proc/swaps
cat /proc/uptime
cat /proc/version
cat /proc/filesystems
cat /proc/net/tcp
cat /proc/net/dev
```

Per-process (replace `1234` with PID):

```
cat /proc/1234/status
cat /proc/1234/cmdline
cat /proc/1234/environ
ls -la /proc/1234/fd
cat /proc/1234/maps
cat /proc/1234/limits
```

Kernel tuning via `/sys`:

```
cat /sys/block/sda/queue/scheduler
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
```
