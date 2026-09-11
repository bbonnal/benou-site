---
title: "Backup"
date: 2026-03-11
tags: ["system", "backup", "borg"]
source: doc/pages/system/backup.md
source_sha: 7ee6700ec8f3
---

> Borg backup to LUKS-encrypted USB drive, and full restore procedure.

## Setup overview

```
USB drive /dev/sda1  →  LUKS2 container "backup"
                              ↓
                    /dev/mapper/backup  →  /mnt/backup
                              ↓
                    /mnt/backup/arch_backup  (borg repo)
```

## Unlock and mount the drive

```
sudo cryptsetup open /dev/sda1 backup
sudo mount --mkdir /dev/mapper/backup /mnt/backup
```

Find the device if unsure:
```
lsblk
sudo blkid | grep crypto
```

## Run a backup

```
sudo borg create --verbose --stats --progress \
    --exclude-from /etc/borg-exclude \
    /mnt/backup/arch_backup::"$(hostname)-$(date +%Y-%m-%d-%H%M%S)" \
    /
```

- Archive name format: `hostname-YYYY-MM-DD-HHMMSS`
- Excludes: `/dev`, `/proc`, `/sys`, `/tmp`, `/run`, `/mnt`, caches, node_modules, `.wine`, etc.
- See `/etc/borg-exclude` for the full list

## List archives

```
sudo borg list /mnt/backup/arch_backup
```

## Unmount and lock when done

```
sudo umount /mnt/backup
sudo cryptsetup close backup
```

---

## Restore procedure

### 1. Unlock and mount the backup drive

Same as above:
```
sudo cryptsetup open /dev/sda1 backup
sudo mount /dev/mapper/backup /mnt/backup
```

### 2. List available archives

```
sudo borg list /mnt/backup/arch_backup
```

Pick the archive name you want to restore from (e.g. `t14s-2025-12-01-120000`).

### 3a. Restore specific files or directories

Extract into current directory (creates paths relative to `/`):
```
sudo borg extract /mnt/backup/arch_backup::t14s-2025-12-01-120000 home/benou/Documents
```

Extract to a specific location — extract to a temp dir then move:
```
mkdir /tmp/restore
cd /tmp/restore
sudo borg extract /mnt/backup/arch_backup::t14s-2025-12-01-120000 home/benou/Documents
# files land at /tmp/restore/home/benou/Documents/
```

### 3b. Full system restore (from live ISO)

Boot a live Arch ISO, decrypt and unlock LUKS on both the backup USB and the system disk, then:

```
# Mount the target system root
sudo cryptsetup open /dev/nvme0n1p2 cryptlvm
sudo mount /dev/MyVolGroup/root /mnt
sudo mount --mkdir /dev/MyVolGroup/home /mnt/home
sudo mount --mkdir /dev/nvme0n1p1 /mnt/efi

# Mount the backup USB
sudo cryptsetup open /dev/sda1 backup
sudo mount /dev/mapper/backup /mnt/backup

# Extract everything from the archive into the target root
cd /mnt
sudo borg extract /mnt/backup/arch_backup::t14s-2025-12-01-120000
```

Then `arch-chroot /mnt` and rebuild the bootloader / initramfs:
```
arch-chroot /mnt
mkinitcpio -p linux
bootctl install
exit
reboot
```

### 4. Inspect archive contents before restoring

Browse what's in an archive without extracting:
```
sudo borg list /mnt/backup/arch_backup::t14s-2025-12-01-120000
```

With a path filter:
```
sudo borg list /mnt/backup/arch_backup::t14s-2025-12-01-120000 home/benou
```

Check a specific file:
```
sudo borg list /mnt/backup/arch_backup::t14s-2025-12-01-120000 | grep ".zshrc"
```

### 5. Mount archive as a filesystem (browse interactively)

```
mkdir /tmp/borg-mount
sudo borg mount /mnt/backup/arch_backup::t14s-2025-12-01-120000 /tmp/borg-mount
# browse with ls/cp/yazi etc.
sudo borg umount /tmp/borg-mount
```

---

## Repo maintenance

- Disk usage and stats:
  `sudo borg info /mnt/backup/arch_backup`

- Prune old archives (keep last 7 daily, 4 weekly, 6 monthly):
  ```
  sudo borg prune --list \
      --keep-daily=7 --keep-weekly=4 --keep-monthly=6 \
      /mnt/backup/arch_backup
  ```

- Compact repo after pruning (reclaim disk space):
  `sudo borg compact /mnt/backup/arch_backup`

- Verify repo integrity:
  `sudo borg check /mnt/backup/arch_backup`

## Init a new repo (first time only)

```
sudo borg init --encryption=none /mnt/backup/arch_backup
```

Current setup uses no encryption (the LUKS layer on the USB provides encryption at rest).
