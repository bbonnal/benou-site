---
title: "Storage"
date: 2026-05-23
tags: ["system", "storage", "disks"]
source: doc/pages/system/storage.md
source_sha: 010b67c6e79b
---

> Disks, partitions, mounting, fstab, BTRFS, LVM, swap, SMART, USB and LUKS.

## Inspect

- Block device tree:
  `lsblk`

- With filesystem info:
  `lsblk -f`

- Custom columns:
  `lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,UUID`

- Detailed partition info:
  `sudo fdisk -l`

- Filesystem usage:
  `df -h`

- Inode usage:
  `df -i`

- UUIDs and labels:
  `sudo blkid`

- Get one UUID:
  `blkid -s UUID -o value /dev/sda1`

- Symlinks by UUID/id/label:
  `ls -l /dev/disk/by-uuid/`

## Mount / umount

- Mount partition:
  `sudo mount /dev/sdb1 /mnt`

- Mount by UUID:
  `sudo mount UUID="xxxx-xxxx" /mnt`

- Mount with type:
  `sudo mount -t ext4 /dev/sdb1 /mnt`

- Mount read-only:
  `sudo mount -o ro /dev/sdb1 /mnt`

- Remount with new opts:
  `sudo mount -o remount,rw /mnt`

- Mount ISO file:
  `sudo mount -o loop image.iso /mnt/iso`

- Mount tmpfs (RAM):
  `sudo mount -t tmpfs -o size=2G tmpfs /mnt/ramdisk`

- Mount NFS:
  `sudo mount -t nfs server:/share /mnt/nfs`

- Unmount:
  `sudo umount /mnt`

- Lazy unmount (detach when free):
  `sudo umount -l /mnt`

- Show mounts:
  `findmnt`

- Find who's holding a mount:
  `fuser -mv /mnt` or `lsof +D /mnt`

## fstab

- File: `/etc/fstab`
- Test entries without rebooting:
  `sudo mount -a`

- Reload systemd-generated mounts:
  `sudo systemctl daemon-reload`

- Example line:
  ```
  UUID=xxxx-xxxx /        ext4 defaults,noatime           0 1
  UUID=yyyy-yyyy /home    ext4 defaults                   0 2
  UUID=zzzz-zzzz /boot    vfat defaults,umask=0077        0 2
  tmpfs          /tmp     tmpfs defaults,noatime,mode=1777 0 0
  ```

| Option | Meaning |
|--------|---------|
| `defaults` | rw, suid, dev, exec, auto, nouser, async |
| `noatime` | no access-time updates (faster) |
| `nofail` | don't fail boot if device missing |
| `x-systemd.automount` | mount on first access |
| `discard` | enable TRIM (SSDs) |
| `compress=zstd` | BTRFS compression |

## Partitioning

- Interactive (MBR/GPT):
  `sudo fdisk /dev/sdb`

- GPT-only:
  `sudo gdisk /dev/sdb`

- Scriptable:
  ```
  sudo parted /dev/sdb mklabel gpt
  sudo parted /dev/sdb mkpart primary ext4 1MiB 100GiB
  sudo parted /dev/sdb resizepart 2 200GiB
  ```

## Format

- ext4:
  `sudo mkfs.ext4 -L data /dev/sdb1`

- BTRFS:
  `sudo mkfs.btrfs -L data /dev/sdb1`

- FAT32 (EFI):
  `sudo mkfs.fat -F32 /dev/sdb1`

- XFS:
  `sudo mkfs.xfs /dev/sdb1`

- Swap:
  `sudo mkswap /dev/sdb2 && sudo swapon /dev/sdb2`

## BTRFS

- Create + mount with compression:
  ```
  sudo mkfs.btrfs -L btrfs-data /dev/sdb1
  sudo mount -o compress=zstd,noatime /dev/sdb1 /mnt/data
  ```

- Create subvolume:
  `sudo btrfs subvolume create /mnt/data/@home`

- List subvolumes:
  `sudo btrfs subvolume list /mnt/data`

- Mount subvolume:
  `sudo mount -o subvol=@home /dev/sdb1 /home`

- Read-only snapshot (for backups):
  `sudo btrfs subvolume snapshot -r /mnt/data/@ /mnt/data/@snapshots/$(date +%F)`

- Filesystem usage:
  `sudo btrfs filesystem usage /mnt/data`

- Scrub (verify checksums):
  `sudo btrfs scrub start /mnt/data && sudo btrfs scrub status /mnt/data`

- Balance:
  `sudo btrfs balance start /mnt/data`

- Defragment:
  `sudo btrfs filesystem defragment -r /mnt/data`

## LVM

PV → VG → LV.

- Create PV:
  `sudo pvcreate /dev/sdb1`

- Create VG:
  `sudo vgcreate myvg /dev/sdb1 /dev/sdc1`

- Create LV (fixed size):
  `sudo lvcreate -L 50G -n mylv myvg`

- Create LV (rest of VG):
  `sudo lvcreate -l 100%FREE -n mylv myvg`

- Format + mount:
  `sudo mkfs.ext4 /dev/myvg/mylv && sudo mount /dev/myvg/mylv /mnt/lvm`

- Show:
  `sudo pvs && sudo vgs && sudo lvs`

- Grow LV + filesystem:
  `sudo lvextend -L +10G --resizefs /dev/myvg/mylv`

- LVM snapshot:
  `sudo lvcreate -L 5G -s -n mysnap /dev/myvg/mylv`

- Remove (reverse order):
  ```
  sudo lvremove /dev/myvg/mylv
  sudo vgremove myvg
  sudo pvremove /dev/sdb1
  ```

## Swap

- Show:
  `swapon --show` or `free -h`

- File-based 4 GiB swap:
  ```
  sudo dd if=/dev/zero of=/swapfile bs=1M count=4096
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  ```

- Disable:
  `sudo swapoff /swapfile`

- Tune swappiness:
  `sudo sysctl vm.swappiness=10` (persist in `/etc/sysctl.d/99-swappiness.conf`)

## SMART

Install `smartmontools`.

- Drive info + SMART support:
  `sudo smartctl -i /dev/sda`

- Enable SMART:
  `sudo smartctl -s on /dev/sda`

- Full attributes/error log:
  `sudo smartctl -a /dev/sda`

- Quick health (PASSED/FAILED):
  `sudo smartctl -H /dev/sda`

- Short self-test:
  `sudo smartctl -t short /dev/sda`

- Long self-test:
  `sudo smartctl -t long /dev/sda`

- NVMe:
  `sudo smartctl -a /dev/nvme0`

- Auto monitoring:
  `sudo systemctl enable --now smartd`

## Disk usage

- One directory size:
  `du -sh /home/jo`

- Top-level breakdown sorted:
  `du -h --max-depth=1 /home/jo | sort -hr`

- Largest files:
  `find / -type f -exec du -h {} + 2>/dev/null | sort -rh | head -20`

- Interactive:
  `ncdu /home`

## USB drive (ext4 / regular)

- Mount:
  `sudo mount --mkdir /dev/sda1 /mnt/usbstick`

- Unmount:
  `sudo umount /mnt/usbstick`

## USB drive (FAT/exFAT — preserve ownership)

Without uid/gid, FAT mounts as root-owned:

- Mount with user ownership:
  `sudo mount -o uid=1000,gid=1000,umask=002 /dev/sda1 /mnt/usbstick`

## LUKS encrypted drive

- Initialize (destructive!):
  `sudo cryptsetup luksFormat --type luks2 /dev/sda1`

- Open (maps to `/dev/mapper/backup`):
  `sudo cryptsetup open /dev/sda1 backup`

- Mount opened volume:
  `sudo mount --mkdir /dev/mapper/backup /mnt/backup`

- Unmount and close:
  `sudo umount /mnt/backup && sudo cryptsetup close backup`

- Inspect headers:
  `sudo cryptsetup luksDump /dev/sda1`

## borg backup (to encrypted or plain mount)

- Initialize:
  `borg init --encryption=none /mnt/backup/arch_backup`

- Create backup:
  ```
  sudo borg create --verbose --stats --progress \
    --exclude-from /etc/borg-exclude \
    /mnt/backup/arch_backup::"$(hostname)-$(date +%Y-%m-%d-%H%M%S)" \
    /
  ```

## rsync (e.g. sync music to DAP)

- Dry run first:
  `rsync -avh --info=progress2 --dry-run /mnt/storage/Music/ /mnt/dap/`

- For real:
  `rsync -avh --info=progress2 /mnt/storage/Music/ /mnt/dap/`
