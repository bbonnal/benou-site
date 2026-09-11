---
title: "System admin"
date: 2026-05-23
tags: ["system", "admin", "systemd"]
source: doc/pages/system/admin.md
source_sha: 5a297ac503e7
---

> Date/time, locale, cron, kernel modules, tmpfiles.d, power, hostname, misc utilities.

## Date & time

- Show:
  `date`
  `date +"%Y-%m-%d %H:%M:%S"`
  `date +%F`

- UTC:
  `date -u`

- Status (tz, NTP, RTC):
  `timedatectl`

- List timezones:
  `timedatectl list-timezones | grep -i europe`

- Set timezone:
  `sudo timedatectl set-timezone Europe/Paris`

- Enable NTP:
  `sudo timedatectl set-ntp true`

- NTP status:
  `timedatectl timesync-status`

- NTP config: `/etc/systemd/timesyncd.conf`:
  ```
  [Time]
  NTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org
  ```

- Hardware clock:
  `sudo hwclock --show`
  `sudo hwclock --systohc`

- Manual set (rarely needed):
  `sudo date -s "2025-01-15 12:00:00"`

### Date arithmetic

- `date -d "+7 days"`
- `date -d "last monday"`
- `date -d "2 hours ago"`
- `date -d "2025-01-01 + 90 days" +%F`

### Epoch

- Now in epoch:
  `date +%s`

- Epoch → human:
  `date -d @1700000000`

## Locale

- Current settings:
  `locale`

- Available:
  `locale -a`

- Generate (edit `/etc/locale.gen` first):
  `sudo locale-gen`

- Set system locale / keymap:
  `sudo localectl set-locale LANG=en_US.UTF-8`
  `sudo localectl set-keymap us`

- Status:
  `localectl status`

- Per-session override:
  ```
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
  ```

## Cron syntax

Prefer systemd timers (see `systemd`). Cron format:

```
┌─ minute (0-59)
│ ┌─ hour (0-23)
│ │ ┌─ day of month (1-31)
│ │ │ ┌─ month (1-12)
│ │ │ │ ┌─ day of week (0-7; 0/7 = Sun)
│ │ │ │ │
* * * * *  command
```

| Expression | Meaning |
|-----------|---------|
| `*/5 * * * *` | every 5 min |
| `0 * * * *` | every hour |
| `0 0 * * *` | daily midnight |
| `0 2 * * *` | daily 02:00 |
| `0 0 * * 0` | Sunday midnight |
| `0 0 1 * *` | 1st of month |
| `30 8 * * 1-5` | Mon–Fri 08:30 |
| `0 */6 * * *` | every 6 hours |

### cronie

Install + enable:
```
sudo systemctl enable --now cronie
```

- Edit / list / remove:
  `crontab -e` / `crontab -l` / `crontab -r`

## Kernel modules

- Loaded modules:
  `lsmod`

- Info on a module:
  `modinfo nvidia`

- Parameters only:
  `modinfo -p nvidia`

- Load (with deps):
  `sudo modprobe nvidia`

- Load with params:
  `sudo modprobe snd_hda_intel power_save=1`

- Unload:
  `sudo modprobe -r nvidia`

- Show deps:
  `modprobe --show-depends nvidia`

- Reload:
  `sudo modprobe -r nvidia && sudo modprobe nvidia`

### Persistent config

- Blacklist (`/etc/modprobe.d/blacklist.conf`):
  ```
  blacklist nouveau
  ```

- Auto-load at boot (`/etc/modules-load.d/custom.conf`):
  ```
  nvidia
  vhost_net
  ```

- Module options (`/etc/modprobe.d/nvidia.conf`):
  ```
  options nvidia NVreg_UsePageAttributeTable=1
  ```

## tmpfiles.d

Format: `Type Path Mode Owner Group Age Argument` in `/etc/tmpfiles.d/*.conf`.

| Type | Action |
|------|--------|
| `d` | create dir |
| `D` | create dir + clean by age |
| `f` | create file (if absent) |
| `F` | create file (truncate) |
| `L` | symlink |
| `R` | remove recursively |
| `r` | remove |
| `z` | adjust perms |
| `Z` | adjust perms recursively |

Examples:
```
d /run/myapp 0755 myuser mygroup -
D /tmp/myapp 0755 root root 7d
L /etc/myapp.conf - - - - /opt/myapp/config/myapp.conf
f /run/myapp/pid 0644 myuser mygroup - ""
R /tmp/old-data -
```

- Apply:
  `sudo systemd-tmpfiles --create`

- Clean by age:
  `sudo systemd-tmpfiles --clean`

- Remove R/r entries:
  `sudo systemd-tmpfiles --remove`

- Dry run:
  `sudo systemd-tmpfiles --create --dry-run`

## Power management

- Shutdown now:
  `sudo poweroff` / `sudo shutdown now`

- Scheduled:
  `sudo shutdown -h +10` / `sudo shutdown -h 22:00`

- Cancel:
  `sudo shutdown -c`

- Reboot:
  `sudo reboot`

- Suspend (RAM):
  `sudo systemctl suspend`

- Hibernate (swap):
  `sudo systemctl hibernate`

- Hybrid:
  `sudo systemctl hybrid-sleep`

- Suspend-then-hibernate:
  `sudo systemctl suspend-then-hibernate`

- logind config (`/etc/systemd/logind.conf`):
  ```
  HandleLidSwitch=suspend
  HandlePowerKey=poweroff
  IdleAction=suspend
  IdleActionSec=30min
  ```

- Reload:
  `sudo systemctl restart systemd-logind`

- Inhibit sleep:
  `systemd-inhibit --what=sleep --who="my-script" --why="downloading" wget URL`

- List inhibitors:
  `systemd-inhibit --list`

- CPU governor:
  `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`

- Set performance:
  `echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor`

- TLP (laptop power):
  ```
  sudo systemctl enable --now tlp
  sudo tlp-stat -b
  ```

## Hostname

- Show:
  `hostname` / `hostnamectl`

- Set persistent:
  `sudo hostnamectl set-hostname myarch`

- Pretty hostname (UI display):
  `sudo hostnamectl set-hostname "My Arch Workstation" --pretty`

- Files: `/etc/hostname`, `/etc/hosts` (`127.0.1.1 myarch`).

## cron vs systemd timer

| Feature | cron | systemd timer |
|---------|------|---------------|
| Logging | syslog/mail | journalctl |
| Dependencies | none | full systemd |
| Missed runs | lost | `Persistent=true` catches up |
| Random delay | no | `RandomizedDelaySec` |
| Resource limits | no | cgroups |
| Calendar syntax | 5 fields | flexible `OnCalendar=` |
| Boot-relative | no | `OnBootSec=`, `OnStartupSec=` |

## Misc utilities

- Repeat command every 2s:
  `watch -n 2 "df -h"`

- Highlight changes:
  `watch -d "free -h"`

- Answer yes to prompts:
  `yes | pacman -S package`

- Low CPU priority:
  `nice -n 19 make -j$(nproc)`

- Low I/O priority (idle class):
  `ionice -c3 rsync -a src/ dest/`

- Timeout:
  `timeout 30 wget URL`

- Timeout with SIGKILL:
  `timeout --signal=KILL 10 command`

- Retry until success:
  `until ping -c1 google.com; do sleep 1; done`

- One-off scheduled:
  `sudo systemd-run --on-active=30min /usr/local/bin/task.sh`
  `echo "reboot" | sudo at 02:00`

- Bulk rename (perl-rename):
  ```
  rename 's/\.jpeg$/\.jpg/' *.jpeg
  rename 'y/A-Z/a-z/' *
  ```

- Random data:
  `head -c 32 /dev/urandom | base64`
  `openssl rand -hex 16`

- Checksums:
  `sha256sum file.txt`
  `sha256sum -c checksums.txt`

- Copy with progress:
  `rsync -ah --progress src dest`

- HTTP server (current dir):
  `python -m http.server 8000`

- Base64:
  `echo "hello" | base64`
  `echo "aGVsbG8K" | base64 -d`

- URL encode/decode (python):
  ```
  python -c "import urllib.parse; print(urllib.parse.quote('hello world'))"
  python -c "import urllib.parse; print(urllib.parse.unquote('hello%20world'))"
  ```

- JSON pretty:
  `jq . data.json`

- ISO from directory:
  `mkisofs -o image.iso /path/to/dir`

- Write ISO to USB:
  `sudo dd if=archlinux.iso of=/dev/sdb bs=4M status=progress oflag=sync`

- System info:
  `fastfetch` / `neofetch`

## Useful one-liners

- Largest files everywhere:
  `find / -type f -exec du -h {} + 2>/dev/null | sort -rh | head -20`

- Kill all matching pattern:
  `pkill -f "pattern"`

- Tail a file:
  `tail -f /var/log/pacman.log`

- Listen / connect port:
  `nc -l 8080` / `nc host 8080`

- Diff dir contents:
  `diff <(ls dir1) <(ls dir2)`

- Count files by extension:
  `find . -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn`
