---
title: "usb-helper"
date: 2026-06-15
tags: ["tools", "usb", "luks"]
source: doc/pages/tools/usb-helper.md
source_sha: f39ab4ef3efe
---

## What This Project Is

A single bash script (`usb-helper`) that provides a graphical menu for mounting,
unmounting, encrypting/decrypting, and ejecting USB drives on Linux. It targets the
Sway window manager on Wayland, using `fuzzel` as the picker.

The user presses a keyboard shortcut, a menu pops up listing their USB drives, they
pick one, then pick an action (mount, unmount, etc.), and the script does the rest
and shows a desktop notification with the result.

The tool is `usb-helper` (~480 lines), meant to be read top to bottom; this guide
explains the parts that aren't obvious from the code. For custom mount points it sources
one shared, audited helper, `lib/elevate.sh` (privilege elevation through fuzzel —
documented in `usb-helper-elevation.md`); everything else is self-contained.

## Target Environment

- **OS**: Arch Linux (rolling release)
- **Window Manager**: Sway (Wayland, not X11)
- **Menu/Launcher**: fuzzel (Wayland-native dmenu replacement)
- **Notifications**: mako + notify-send
- **Shell**: bash 4.3+ (associative arrays + namerefs; the script checks this at startup)

## Required System Packages

| Package      | Provides                | Why we need it                              |
|--------------|-------------------------|---------------------------------------------|
| `udisks2`    | `udisksctl`             | Mount/unmount/unlock WITHOUT sudo           |
| `util-linux` | `lsblk`, `findmnt`      | List block devices (JSON) / query mountpoint|
| `jq`         | `jq`                    | Parse the JSON from `lsblk`                 |
| `fuzzel`     | `fuzzel`                | Show the interactive menus (needs `--index`)|
| `libnotify`  | `notify-send`           | Desktop notifications                       |
| `cryptsetup` | (used by udisks2)       | LUKS encryption/decryption                  |

Optional filesystem support: `ntfs-3g` (NTFS), `exfatprogs` (exFAT).

> **Minimum versions:** util-linux ≥ 2.37 (for the plural `MOUNTPOINTS` lsblk column)
> and a `fuzzel` with dmenu `--index` support. Both are satisfied by current Arch.

## How The Script Works

```
main()
  └─ load_config()        read optional ~/.config/usb-helper/drives.conf
  └─ show_device_menu()   list USB drives -> fuzzel -> pick one
       └─ show_action_menu()  offer state-appropriate actions -> fuzzel -> pick one
            └─ do_mount / do_unmount / do_unlock / do_lock / do_power_off
                 └─ notify()  desktop notification with the result
```

Read the functions in that order. Below are the parts worth explaining.

### Device discovery — `list_usb_devices()`

Runs `lsblk -J -o NAME,PATH,SIZE,FSTYPE,MOUNTPOINTS,LABEL,UUID,TYPE,TRAN` and pipes
the JSON through one `jq` program that returns a flat array of "device records".

The `jq` program defines a helper `record($disk)` that folds each device — plain or
LUKS — into the same flat shape, so **no other function ever has to walk the device
tree again**. The important computed fields:

- `is_luks` — the partition is `crypto_LUKS` (encrypted)
- `is_unlocked` — a LUKS partition that has been decrypted (it gained a `crypt` child)
- `is_mounted` / `mount_path` — read from the decrypted child if unlocked, else the node itself
- `luks_child_path` — the node you actually mount when unlocked (e.g. `/dev/mapper/luks-…`); `null` if locked
- `effective_fstype` — for LUKS, the inner filesystem (e.g. ext4 inside the encryption)
- `path` / `disk_path` — the device node and its parent disk node, taken straight
  from lsblk's `PATH` column (see "Why PATH" below)

**The LUKS device tree.** An encrypted partition gains a decrypted `crypt` child once
unlocked:
```
sdb        (disk, tran=usb)
└─sdb1     (part,  fstype=crypto_LUKS)   <- the partition we unlock/lock
  └─dm-0   (crypt, fstype=ext4)          <- the decrypted node we mount  (PATH = /dev/mapper/luks-…)
```
`record()` reads mount state from the `crypt` child when present, so an unlocked
drive reports the inner filesystem and its real mountpoint.

**Two kinds of device qualify** (the two branches at the end of the `jq` program):
- **A.** Partitions (`type == "part"`) on a USB disk.
- **B.** A whole-disk USB that carries a filesystem *directly* (no partition table),
  **including whole-disk LUKS**. Branch B deliberately still matches a disk that has a
  `crypt` child (an *unlocked* whole-disk LUKS) and only excludes disks that have real
  partitions. This is what keeps a whole-disk LUKS stick from vanishing from the menu
  the moment you unlock it.

### Menu display — `format_device_line()` and selection by index

`format_device_line()` turns one record into a single aligned line, e.g.:
```
/dev/sdb1       "MyUSB"           32G  ext4            [Not mounted]
/dev/sdc1       "Backup"          64G  LUKS(ext4)      [Locked]  -> /mnt/backup
```
Newlines in a label are stripped so each device stays on exactly one line.

`show_device_menu()` feeds those lines to `fuzzel --dmenu --index`. Fuzzel returns the
**index** of the chosen line, and we pick `devices_json[index]` directly. We never parse
the displayed text back into a device — that would be fragile when labels contain spaces.

### Action menu — `show_action_menu()`

Offers only the actions that make sense for the drive's current state:

| State                          | Actions offered                                   |
|--------------------------------|---------------------------------------------------|
| Plain, not mounted             | Mount · Power Off                                 |
| Plain, mounted                 | Unmount · Unmount + Power Off                     |
| LUKS, locked                   | Unlock · Power Off                                |
| LUKS, unlocked, not mounted    | Mount · Lock · Power Off                          |
| LUKS, unlocked, mounted        | Unmount · Unmount + Lock · Unmount + Lock + Power Off |

Compound actions chain with `&&`, so a later step runs only if the earlier one succeeded.

### The actions

- **`do_mount`** — `udisksctl mount` for normal drives (no root); for drives with a
  custom mount point in `drives.conf` it elevates via `run_elevated mount …` (the
  shared `lib/elevate.sh`; see "Privilege elevation" below). For LUKS it mounts the
  decrypted child (`luks_child_path`), not the encrypted partition. The mountpoint shown
  in the notification comes from `findmnt`, not from scraping udisksctl's text.
- **`do_unmount`** — mirror of `do_mount` (`run_elevated umount …` for custom points).
- **`do_unlock`** — collects the passphrase, runs `udisksctl unlock --key-file`, then
  **re-scans devices and re-opens this drive's action menu** so the user can mount
  straight away. This is the one piece of non-linear control flow: `do_unlock` calls
  `show_action_menu`, which is defined later in the file (fine in bash — it only needs
  to exist by the time it's *called*).
- **`do_lock`** — `udisksctl lock` (drive must be unmounted first).
- **`do_power_off`** — `udisksctl power-off` on the whole **disk** (`disk_path`). This
  affects every partition on the disk; udisksctl refuses while any is still mounted/
  unlocked, and we translate that into a clear "eject is disk-wide" message.

### Privilege elevation — `lib/elevate.sh` (custom mount points only)

Custom mount points in `drives.conf` need root (only root can mount to an arbitrary
path). The script obtains it through the shared, audited helper `lib/elevate.sh`,
sourced once near the top into `run_elevated` / `run_elevated_fresh`. It prompts for the
sudo password with `fuzzel` (a `SUDO_ASKPASS` helper, `lib/sudo-askpass-fuzzel.sh`) and
keeps the password on a **memory-only pipe** — fuzzel → askpass stdout → sudo → PAM —
with **no temp file at all**. `do_mount` / `do_unmount` call `run_elevated mount …` /
`run_elevated umount …`. Full rationale and threat model: `usb-helper-elevation.md`.

- **Sourcing is guarded and optional.** `elevate.sh` refuses to arm (and its `source`
  returns non-zero) if the helper is missing or writable by other users. We source it as
  `if . "$SELF_DIR/lib/elevate.sh"; then ELEVATION_OK=1; fi` so a non-arming return can't
  abort us under `set -e`, and the udisksctl / LUKS flows still work. A custom-mount
  action checks `ELEVATION_OK` and notifies a clear failure if it's 0.
- **`SELF_DIR` uses `readlink -f`** on `${BASH_SOURCE[0]}` so `lib/` is found next to the
  *real* script even when invoked through a symlink (e.g. a dotfiles `bin/` link).

### Secret handling — `collect_passphrase()` / `cleanup_passphrase()` (LUKS only)

The **LUKS passphrase** is written to a short-lived file on a RAM-backed filesystem
(`$XDG_RUNTIME_DIR`, falling back to `/dev/shm`) because `udisksctl unlock --key-file`
needs a file. This path is **LUKS-only** — the sudo password no longer comes through
here (it goes via `lib/elevate.sh`, which uses no file; see above).

The file path lives in one global, `PASSPHRASE_FILE`, and is removed by an
**EXIT/INT/TERM/HUP trap** plus an explicit `cleanup_passphrase` right after use. See
"Why EXIT, not RETURN" below — this is a deliberate robustness choice, not an accident.

## Robustness Invariants (read before changing anything)

These are the rules the rewrite relies on. Breaking one reintroduces a real bug.

- **`set -euo pipefail` is on.** Any *unguarded* command that fails aborts the whole
  script. So every command whose failure is expected is either the condition of an
  `if`/`while`, the left side of `&&`/`||`, or ends with `|| true`. Every action
  notifies the user *before* it `return 1`s; after a single menu action there is nothing
  left to do, so the script just ends.

- **Capture in an `if`, not a bare assignment.** `if ! x=$(cmd); then …` keeps a failing
  command substitution from silently killing the script (see `show_device_menu`).

- **Why EXIT, not RETURN, for passphrase cleanup.** A `trap … RETURN` does **not** fire
  when `set -e` aborts a function or a signal arrives — which is exactly when the LUKS
  passphrase file would be left behind. An EXIT trap (plus signal traps that exit) always
  runs. Tested: a wrong LUKS passphrase, a failed unlock, and a cancelled prompt all leave
  no file in the RAM dir. (The sudo password uses no file at all — see `lib/elevate.sh`.)

- **Never parse udisksctl's human-readable text.** It is English- and version-specific.
  Mount paths come from `findmnt`; device identity and the decrypted child come from
  lsblk's JSON. (The system `grep` here is even ugrep, not GNU grep — another reason
  not to depend on prose parsing.)

- **Why `PATH` from lsblk.** A decrypted LUKS node is *named* `dm-0` but its real node is
  `/dev/mapper/luks-…`. Hand-building `/dev/$name` would target the wrong path. lsblk's
  `PATH` column gives the canonical node, so the script never constructs a path.

- **A function's last statement must not be a failing `&&`.** `[[ -n "$x" ]] && y=z`
  returns non-zero when `x` is empty; if that's the *last* line of a function called as a
  bare command, `set -e` aborts the caller. Use `[[ -z "$x" ]] || y=z` or an explicit
  `return 0` (see `flush` inside `load_config`).

### Known limitations (intentional, documented here so they're not "bugs")

- **USB detection is `tran == "usb"`.** Some drives behind unusual bridges report a
  different transport. Broadening the filter (e.g. to all removable/hotplug disks) risks
  matching internal disks — and `do_power_off` could then eject the wrong one — so the
  filter stays conservative.
- **`shred` on tmpfs is best-effort.** tmpfs lives in RAM and can be swapped, so `shred`
  doesn't give a hard secure-erase guarantee here. It's cheap insurance; the real
  protection is that the file is tiny, mode 600, in a per-user RAM dir, and deleted
  immediately after use.
- **LUKS containing LVM** (a `crypt` child that is itself a container) is handled at the
  `crypt` layer only; nested logical volumes aren't enumerated.

## Config File — `~/.config/usb-helper/drives.conf`

Optional, INI-style, parsed by `load_config()`. Maps a drive UUID to a custom mount
point (mounted via `sudo` because only root can mount to an arbitrary path).

```ini
[backup]                       # section name is just a human label
uuid        = abc-def-123      # partition UUID from: lsblk -o NAME,UUID,LABEL,FSTYPE
mount_point = /mnt/backup      # mount here instead of /run/media/$USER/<label>
post_mount  = Run your backup  # REMINDER shown as a notification — plain text, NOT executed
```

For LUKS drives, use the UUID of the `crypto_LUKS` partition (what lsblk shows while the
drive is locked). `lookup_config()` checks both the partition UUID and the LUKS UUID.

If the file doesn't exist, every drive uses the default udisks2 mount location.

## Key Concepts for Non-Bash Developers

The script keeps inline comments to the *non-obvious* bits; the bash basics live here.

- **`set -euo pipefail`** — exit on any error (`-e`), error on unset variables (`-u`),
  and make a pipeline fail if any stage fails (`-o pipefail`). See the robustness rules
  above for how the code stays correct under `-e`.
- **`local`** — declares a variable scoped to the current function.
- **`local -n map="$1"`** — a *nameref*: `map` becomes an alias for the variable whose
  name is in `$1`. `lookup_config` uses it to read whichever associative array you pass.
- **`declare -A NAME`** — an associative array (dictionary). `NAME[key]=value` to set,
  `${NAME[key]:-default}` to read with a fallback.
- **`$(...)`** — command substitution: run the command, substitute its output.
- **`<<< "$var"`** — here-string: feed a variable to a command's stdin (how we pass JSON
  to `jq`).
- **`${var:+text}`** — expands to `text` only if `var` is non-empty (used to append
  optional bits like `  -> /mnt/backup`).
- **String trimming** — `${line%%#*}` drops everything from the first `#`; the
  `${line#"${line%%[![:space:]]*}"}` pair strips leading/trailing whitespace. These are
  the cryptic lines in `load_config`.
- **`jq -r`** — raw output (no quotes). `.a // ""` means "field `a`, or `""` if null".
  `select(...)` filters; `def name: …;` defines a reusable filter (we use `record`).
- **`trap CMD EXIT`** — run `CMD` when the shell exits (for any reason). We use it so the
  passphrase file is always cleaned up.
- **`/dev/shm` and `$XDG_RUNTIME_DIR`** — RAM-backed filesystems; files there normally
  never touch the physical disk.

## How To Test

**Manual:** plug in a USB drive, run `usb-helper` from a terminal (or bind it in
sway), and step through the menus. With no drive plugged in you should get a
"No USB devices found" notification.

**Without hardware:** the script reads everything through external commands, so you can
exercise the full flow by putting stub `lsblk`/`fuzzel`/`udisksctl`/`findmnt`/
`notify-send`/`sudo` executables earlier on `PATH`: have `lsblk` print a synthetic JSON
tree, have `fuzzel` print a fixed index/action, and have `notify-send` log its arguments.
This is how the device model, the unlock→re-scan→mount flow, the compound teardown, and
the no-passphrase-leak guarantees were verified.

**Static checks:** `bash -n usb-helper` (syntax) and, if installed, `shellcheck`.

## Debugging Tips

- See what lsblk reports: `lsblk -J -o NAME,PATH,SIZE,FSTYPE,MOUNTPOINTS,LABEL,UUID,TYPE,TRAN`.
  USB drives must show `"tran": "usb"`.
- Run from a terminal to see stderr.
- LUKS issues: `udisksctl status`, `udisksctl dump`.
- Notification issues: `journalctl --user -e`.

## Deployment & Location

Deployed from the dotfiles via GNU Stow (`stow -v .` from `~/Dotfiles`):

- `~/.local/bin/usb-helper` (+ `format-usb`, `set-partition-type`) — on `$PATH`
- `~/.local/bin/lib/elevate.sh`, `~/.local/bin/lib/sudo-askpass-fuzzel.sh` — the shared helper
- `~/.config/usb-helper/drives.conf.example` — copy to `drives.conf` to add custom mount points
- Sway: bound to `$mod+u` in `~/.config/sway/config`

`format-usb` / `set-partition-type` are CLI-only (destructive/occasional — no keybinding).
The scripts resolve their own `lib/` via `readlink -f`, so they work through the Stow symlinks.

## Future Work (Not Yet Implemented)

- `install.sh` (dependency check + config directory setup)
- Optional: udiskie daemon for automatic mount-on-plug
