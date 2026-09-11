---
title: "QEMU USB storage passthrough"
date: 2026-08-23
tags: ["tools", "qemu", "udev"]
source: doc/pages/tools/qemu-usb-storage-attach.md
source_sha: 7774055553a0
---

> Making a USB stick / card reader / board-as-mass-storage show up inside the Windows 10
> VM (`~/VMs/run_win10.sh`), and fixing the `/dev/bus/usb` permission problem that
> silently stops it. Verified on Atmel AVR32 UC3 (`03eb:2301`, USB2, one LUN) and a
> Genesys Logic multi-slot card reader (`05e3:0764`, USB3, four LUNs).

The VM tooling lives in `~/VMs` (`run_win10.sh`, `vm-usb.sh`, `docs/usb-passthrough.md`).
This page is the part that isn't in those docs: the **diagnosis**, because the failure
is silent and looks like success.

## The 30-second version

```sh
cd ~/VMs
./vm-usb.sh list                      # find VID:PID and BUS-PORT
lsblk -o NAME,MOUNTPOINT,TRAN,MODEL   # mass storage: must NOT be mounted on the host
udisksctl unmount -b /dev/sdX1        # ...unmount EVERY mounted node of that device

# one-time per device: let QEMU (running as you) claim the USB node
sudoedit /etc/udev/rules.d/70-<name>.rules       # content in "The udev rule" below
sudo udevadm control --reload
sudo udevadm trigger --action=add --subsystem-match=usb

getfacl -p /dev/bus/usb/003/006 | grep benou     # must show  user:benou:rw-
./vm-usb.sh attach 3-1                           # by physical port
./vm-usb.sh attached                             # verify — see "Reading the result"
```

## Why this needs a udev rule at all

QEMU runs as **your user**, not root. To take a USB device away from the host kernel and
hand it to the guest, it must open the device's usbfs node — `/dev/bus/usb/<bus>/<dev>` —
**read-write**. Out of the box that node is:

```
crw-rw-r--  1 root root  189, 261  /dev/bus/usb/003/006
```

`root:root`, and you are neither → you get read-only → **the claim fails**.

The trap: read-only access is enough for QEMU to *enumerate* the device, so
`./vm-usb.sh hostusb` (`info usbhost`) happily lists it, and `device_add` returns
**no error on the monitor**. Everything looks fine. It isn't.

## Reading the result — success vs. silent failure

This is the single most useful thing on this page. Run `./vm-usb.sh attached`:

**Failed claim** — a stub device with a generic name, no real speed:

```
  Device 0.0, Port 3, Speed 1.5 Mb/s, Product USB Host Device, ID: usb_3_1
                                              ^^^^^^^^^^^^^^^  placeholder
```

**Successful claim** — the device's own product string and its true speed:

```
  Device 0.2, Port 2, Speed 480 Mb/s, Product AVR32 UC3 MASS STORAGE, ID: usb_3_1
  Device 0.2, Port 3, Speed 5000 Mb/s, Product USB Storage, ID: usb_4_1_2
```

(`5000 Mb/s` = a real USB3 claim; the guest's `qemu-xhci` controller supports it. Duplicate
`Device 0.2` numbers across different ports are normal and not a problem.)

Three independent tells, any one of which is enough:

| Check | Failed | Worked |
|---|---|---|
| `./vm-usb.sh attached` | `Product USB Host Device`, `1.5 Mb/s` | real product string, real speed |
| `lsblk \| grep sda` | host still lists the disk | **gone** from the host |
| `getfacl -p /dev/bus/usb/003/006` | no `user:benou` line | `user:benou:rw-` |

The real error message does **not** go to the monitor socket — it goes to the terminal
that launched `run_win10.sh`, as:

```
libusb: error [...] could not open /dev/bus/usb/003/006: Permission denied
```

Keep that terminal visible when debugging passthrough.

## Background: udev, rules, and ACLs

Skip if you already know this. It explains *why* the fix looks the way it does.

### What udev is

`systemd-udevd` is the **device manager**: a root daemon that reacts to hardware events.

```
you plug in a device
  → kernel builds the device, emits a "uevent" over a netlink socket
    → systemd-udevd receives it
      → matches it against every rule in the rules directories
        → acts: create/name the /dev node, set owner/group/mode, add symlinks,
                set properties (ENV) and tags, optionally run programs
          → other daemons (logind, udisks2, ModemManager…) react to the result
```

Two things follow. First, **the `/dev` node's permissions are policy, not physics** — some
rule decided them, and a rule can decide differently. Second, **udevd runs as root**, so a
rule can grant any access it likes. That is why `/etc/udev/rules.d/` must stay root-owned:
write access to it is effectively root.

### What a rule file is

Plain text, one rule per line, comma-separated key/value clauses. Two kinds of clause:

| Kind | Operators | Meaning |
|---|---|---|
| **Match** | `==` `!=` | conditions; *all* must hold or the line is skipped |
| **Assign** | `=` `+=` `:=` | actions taken when the line matches |

`=` replaces, `+=` appends to a list (correct for `TAG`, `SYMLINK`), `:=` assigns and
**forbids later rules from changing it** (that's why `99-platformio-udev.rules` uses
`MODE:="0666"` — it's staking a claim).

Rules live in three directories, merged and processed in **filename order** regardless of
which directory they came from:

| Directory | Who owns it |
|---|---|
| `/usr/lib/udev/rules.d/` | packages — don't edit, upgrades overwrite |
| `/run/udev/rules.d/` | runtime, volatile |
| `/etc/udev/rules.d/` | **you**; an identical filename here shadows the package one entirely |

Every rule that matches gets applied, so ordering decides who wins — and it's what makes
the `73-` constraint below matter.

Matching device attributes comes in two flavours, and mixing them up is the most common
reason a rule silently never fires:

- `ATTR{...}` / `SUBSYSTEM` — the device **itself**.
- `ATTRS{...}` / `SUBSYSTEMS` — the device **or any ancestor** in the tree. Useful when you
  match a USB *interface* by its parent device's vendor id.

### Why plain Unix permissions can't express what we need

A file has exactly **one owner, one group, and "everyone else"** — three sets of `rwx`
bits. There is no way to say "this one user may use this one device". That constraint is
the whole reason ACLs exist here. The two rule-only workarounds are both bad:

| Approach | Problem |
|---|---|
| `GROUP="plugdev"` | needs a group that exists and that you're a member of — **there is no `plugdev` group on this system**. It also grants access to that group in *every* session, including remote SSH and inactive sessions. |
| `MODE="0666"` | grants **every user on the machine** read-write on the device, forever, logged in or not |

### What an ACL is

A POSIX **Access Control List** adds named entries on top of the classic bits, so you can
grant a specific user or group without changing the owner. `getfacl` shows them:

```
# file: /dev/bus/usb/004/005
user::rw-              ← the owner (root)
user:benou:rw-         ← a NAMED entry: this is the grant that makes passthrough work
group::rw-             ← the owning group (root)
mask::rw-              ← ceiling on all named entries (see below)
other::---             ← everyone else: nothing
```

`ls -l` marks an ACL with a trailing `+`:

```
crw-rw-r--+ 1 root root 189, 388 /dev/bus/usb/004/005
          ^ this plus sign is the only hint in a normal listing
```

Two traps worth knowing. **`mask`** is an upper bound on every named entry — if `mask` is
`r--`, then `user:benou:rw-` effectively grants only read, and `getfacl` prints an
`#effective:` comment when that happens. And **`ls -l`'s group column shows the mask, not
the real group permissions**, once an ACL is present.

### How `uaccess` ties it together

`TAG+="uaccess"` doesn't set an ACL. It attaches a **label**, which a system rule consumes:

```
/usr/lib/udev/rules.d/73-seat-late.rules:16
TAG=="uaccess|xaccess-*", ENV{MAJOR}!="", RUN{builtin}+="uaccess"
```

That builtin asks **systemd-logind** to grant a POSIX ACL to the user of the currently
**active local seat session**. Consequences that plain `MODE`/`GROUP` can't give you:

- it names *you*, not a group, and nobody else gains anything;
- it is **dynamic** — switch VT to another user and the ACL follows the active session;
- it does **not** apply to inactive or remote (SSH) sessions, so a logged-out you has no
  access either;
- it disappears when the device is unplugged, since the node itself goes away.

**Hence the numbering rule: a `uaccess` rule must sort before `73-`.** In a `99-*.rules`
file the tag would be set *after* the rule that reads it, and would do nothing at all.

## The udev rule

`/etc/udev/rules.d/70-atmel-uc3-msc.rules` — the one written for `03eb:2301`:

```udev
# Atmel AVR32 UC3 board that presents itself as USB mass storage.
# TAG+="uaccess" gives the logged-in seat user an ACL on the /dev/bus/usb node,
# which is what QEMU needs to claim the device for the Windows guest.
SUBSYSTEM=="usb", ATTR{idVendor}=="03eb", ATTR{idProduct}=="2301", \
    MODE="0660", TAG+="uaccess"
```

Token by token:

| Token | Meaning / gotcha |
|---|---|
| `SUBSYSTEM=="usb"` | matches the device itself. Singular = *this* device; plural `SUBSYSTEMS` walks up the parent chain. Pair `SUBSYSTEM` with `ATTR`, and `SUBSYSTEMS` with `ATTRS`. |
| `ATTR{idVendor}=="03eb"` | **lowercase hex, exactly 4 digits, no `0x`**. `lsusb` prints it in the right form already. `3eb` or `03EB` silently never matches. |
| `MODE="0660"` | base permissions. On its own this changes nothing useful for you — the file stays `root:root`. It's the ACL below that grants access. |
| `TAG+="uaccess"` | the actual mechanism. `+=` **appends** to the tag list — never use `=` here, it would wipe tags other rules set. |
| `\` at line end | line continuation. No trailing whitespace after the backslash or the rule breaks. |

The mechanism and the sub-73 numbering constraint are explained under
[Background](#how-uaccess-ties-it-together) above. Short version: the tag is only a label,
`73-seat-late.rules` is what turns it into the ACL, so the file must sort before `73-`.

### What the rule actually grants (and takes away)

Compare a node covered by one of these rules against an untouched one:

```
/dev/bus/usb/004/005   (ruled)        /dev/bus/usb/003/002   (untouched)
user::rw-                             user::rw-
user:benou:rw-    ← gained            group::rw-
group::rw-                            other::r--        ← still there
other::---        ← lost              
```

So the rule does **two** things: it grants you read-write via the ACL, and — because
`MODE="0660"` drops the world-readable bit — it *removes* the read access other local users
previously had. Slightly more restrictive for everyone else, which is the direction you want.

**What `user:benou:rw-` on a usbfs node means concretely:** the ability to speak the raw USB
protocol to that device — arbitrary control transfers, bulk reads and writes, claiming
interfaces, and detaching the kernel's driver. For a *storage* device that means reading and
writing **every sector**, which bypasses filesystem permissions entirely. Note that you are
**not** in the `disk` group (`50-udev-default.rules:93` puts block devices there), so you
cannot read `/dev/nvme0n1` or a raw `/dev/sda` — but through the usbfs node you *can* read
and write that card's raw sectors. That is a real, if narrow, privilege expansion. It is
bounded to the matched `VID:PID`, to your active local session, and it is revocable by
deleting the file.

Two lesser implications: any process running as you can **yank the device from the host
kernel** (the same detach QEMU performs), making `/dev/sda` vanish for everyone including
root; and on a device that accepts firmware writes, raw access is enough to **reflash it**.
For the UC3 board that is arguably the point, but it's worth knowing you granted it.

### The three mechanisms on this machine (don't cargo-cult the wrong one)

`/etc/udev/rules.d/` here contains all three styles. They are not equivalent:

| Style | Example | Verdict |
|---|---|---|
| `TAG+="uaccess"` | `49-stlinkv2-1.rules`, and this rule | **preferred** — per-session ACL, least privilege |
| `MODE="0666"` | `99-jlink.rules`, `99-platformio-udev.rules` | works from any filename number (udev applies MODE itself), but makes the device **world**-read-write |
| `GROUP="plugdev"` | `49-stlink*.rules` | **inert here — there is no `plugdev` group on this system** (`getent group plugdev` is empty). Those rules only work because they *also* carry `uaccess`. |

So: don't copy a `99-…` + `MODE="0666"` rule and add `uaccess` to it — the tag would be
set too late to matter.

## Is this only because QEMU runs as your user?

Essentially yes. Root bypasses these permission checks, so a root-run QEMU would need no
rule at all. But that's a bad trade: QEMU is a large C program whose entire job is parsing
input controlled by the guest, and a guest-to-host escape in a root QEMU is a **root**
compromise of the laptop. Running it as you means an escape gets *your* account — bad, but
survivable, and `run_win10.sh` is built around that choice.

The interesting detail is *which* access is missing. usbfs distinguishes two levels:

| Operation | Needs | Result here |
|---|---|---|
| read descriptors, enumerate | node opened **read-only** | works without the rule — this is why `./vm-usb.sh hostusb` lists the device and misleads you |
| claim interface, detach kernel driver, transfer data | node opened **read-write** | fails without the rule |

That split is exactly the silent failure at the top of this page: enumeration succeeds,
the claim doesn't, and `device_add` reports nothing.

For comparison, libvirt's system instance solves the same problem the managed way — it runs
QEMU as a dedicated `qemu` user and grants per-device access when a VM starts, instead of
standing udev rules. Same principle (don't run QEMU as root; grant it exactly one device),
more machinery.

## Would this be any different on Linux?

Three different questions hide in there:

**A Linux guest instead of Windows — no difference at all.** Everything on this page is
host-side. QEMU claims the device and emulates an xHCI controller; what the guest does with
the USB device it sees is the guest's business. The udev rule, the ACL, the unmount-first
rule are all identical. (Though for a Linux guest you'd often skip passthrough entirely and
share files via virtiofs.)

**Just using the device on this Linux host — no rule needed.** Plugging in the card and
opening it in a file manager works with none of this, because you never touch the raw
device: `udisks2` does. `udisksd` runs as **root** and asks **polkit** whether your session
may mount removable media; polkit's default policy says yes for an active local session.
That's a completely separate permission system from udev/ACLs — authorization by *policy for
a request*, not by *file permissions on a node*. So:

| Task | Mechanism | Rule needed? |
|---|---|---|
| Mount the card in your file manager | udisks2 + polkit (root daemon acts for you) | no |
| `udisksctl mount -b /dev/sda1` | same | no |
| Pass the device to a VM (QEMU/libusb) | direct usbfs access **as you** | **yes** |
| `dfu-util`, `st-flash`, `openocd`, `esptool` | same direct usbfs access | **yes** — this is what `49-stlink*.rules` are for |

The dividing line is whether *your* process opens the device, or a root daemon does it on
your behalf.

**Does the rule break normal host use?** No. The ACL only *adds* your access; udisks2 keeps
working exactly as before, and the card auto-mounts normally whenever the guest isn't
holding it. The only behavioural change is that other local users lose the read bit they
had on that one node.

## Doing it again for any other device

1. **Identify it.**
   ```sh
   cd ~/VMs && ./vm-usb.sh list
   ```
   Note both columns: `VID:PID` (identity) and `BUS-PORT` (physical socket).
   For a device that only appears briefly, watch it arrive with `udevadm monitor --udev`.

2. **Confirm the permission theory** before writing any rule:
   ```sh
   udevadm info -q path -n /dev/bus/usb/003/006     # sanity: right node?
   getfacl -p /dev/bus/usb/003/006                  # no user:<you> line → this page applies
   ```
   Find the node number for a device with `lsusb` (`Bus 003 Device 006` → `003/006`).
   It **changes on every replug** — which is exactly why the fix is a udev rule keyed to
   the device identity, not a `chown` on a path.

3. **Write the rule** — substitute your own vendor/product and a descriptive filename,
   keeping the number under 73:
   ```sh
   sudoedit /etc/udev/rules.d/70-my-device.rules
   ```
   ```udev
   SUBSYSTEM=="usb", ATTR{idVendor}=="ffff", ATTR{idProduct}=="ffff", \
       MODE="0660", TAG+="uaccess"
   ```

4. **Apply it.** Reload, then re-fire the `add` event (the ACL is applied on `add`, so a
   reload alone does nothing to already-plugged devices):
   ```sh
   sudo udevadm control --reload
   sudo udevadm trigger --action=add --subsystem-match=usb
   ```
   Physically replugging the device works just as well.

5. **Verify, then attach.**
   ```sh
   getfacl -p /dev/bus/usb/003/006     # want: user:benou:rw-
   ./vm-usb.sh attach 3-1              # or: ./vm-usb.sh attach ffff:ffff
   ./vm-usb.sh attached                # check against "Reading the result" above
   ```

To have it present from boot instead of hot-plugging: `./run_win10.sh --usb 3-1`.

### Test a rule without applying it

```sh
udevadm test /sys/bus/usb/devices/3-1 2>&1 | grep -iE 'uaccess|MODE|rules.d'
```

Shows which rule files matched and whether the tag was set — much faster than
reload/trigger/replug cycles.

## Port vs. VID:PID — they interact, and it's subtle

`vm-usb.sh` lets you attach either way:

- **`3-1` (bus-port)** follows the physical socket. Survives resets and mode changes —
  prefer it for anything you flash or reset.
- **`03eb:2301` (VID:PID)** follows the device identity. A board that re-enumerates under
  a different id (DFU, bootloader) slips out of the guest.

**But the udev rule is keyed to VID:PID.** So if the UC3 drops into its DFU/bootloader
mode, it comes back as a *different* product id — the port-based attach still targets the
right socket, but the ACL no longer covers the new identity, and you're back to
`Permission denied`. Two options:

```udev
# a) a second rule for the bootloader id (find it with: udevadm monitor --udev)
SUBSYSTEM=="usb", ATTR{idVendor}=="03eb", ATTR{idProduct}=="<dfu-pid>", \
    MODE="0660", TAG+="uaccess"

# b) or cover the whole vendor — simpler, but grants any Atmel device
SUBSYSTEM=="usb", ATTR{idVendor}=="03eb", MODE="0660", TAG+="uaccess"
```

## Mass-storage-specific hazards

Passing a *storage* device through is riskier than a debug probe, because the host also
knows how to use it.

- **One USB device can be several block devices.** A multi-slot card reader exposes one
  LUN per slot, so `05e3:0764` produced `sda`, `sdb`, `sdc`, `sdd` from a *single* device —
  the empty slots showing as `0B` are the giveaway. You pass through the **whole reader**,
  which takes every slot with it. So unmount *all* of its mounted nodes, and expect *all*
  of them to vanish from the host.

  Never guess the mapping from size or model — map each node to its USB parent:
  ```sh
  for d in /sys/block/sd*; do
      printf '%-4s -> %s\n' "${d##*/}" "$(readlink -f "$d" | sed 's|/host.*||')"
  done
  ```
  The trailing path component is the `BUS-PORT` you attach (`.../usb4/4-1/4-1.2/...` →
  `4-1.2`). This is worth doing even when it seems obvious: the card in the reader's first
  slot happened to be **7.4 GB with a 63 MB vfat partition — exactly like the Atmel
  board's firmware volume**. Identical geometry, completely different device.

- **Unmount on the host first.** Host and guest both writing one filesystem corrupts it.
  QEMU detaches the kernel `usb-storage` driver when it claims the device, but it will not
  save you from a filesystem the host had already mounted.
  ```sh
  lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,TRAN,MODEL
  udisksctl unmount -b /dev/sda1
  ```
  In the worked example `/dev/sda1` (63 MB vfat) was already unmounted, so passthrough was
  safe immediately. If your desktop auto-mounts on plug, unmount before every attach.
- **Confirm the host let go.** After a successful attach the disk — every LUN of it —
  **disappears** from `lsblk` entirely. If any is still there, the guest has a stub (see the
  failure signature).
- **Windows may offer to format it.** If the partition is something Windows can't read, it
  pops "You need to format the disk before you can use it" — **say no** on a board whose
  mass storage *is* its firmware volume; formatting erases it.
- **Swapping media inside a card reader** is often not re-detected by the guest. Detach and
  re-attach:
  ```sh
  ./vm-usb.sh detach 3-1 && ./vm-usb.sh attach 3-1
  ```
- For a card you only need to *read*, copying through the shared folder (`Z:` in the guest,
  `~/VMs/share`) is far less trouble than passthrough.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `Product USB Host Device`, `1.5 Mb/s` in `attached` | claim failed — almost always permissions. Check `getfacl`. |
| `libusb: ... Permission denied` in the VM's terminal | same; the udev rule is missing, mis-typed, or numbered ≥ 73 |
| ACL still absent after reload | forgot `udevadm trigger --action=add` (or replug); or `idVendor`/`idProduct` not lowercase 4-digit hex |
| Rule seems ignored entirely | filename must end in `.rules`; check with `udevadm test /sys/bus/usb/devices/3-1` |
| `no monitor socket at /run/user/1000/win10_22h2/monitor.sock` | the VM isn't running — start `./run_win10.sh` |
| Device listed by `hostusb` but attach does nothing | expected — enumeration only needs read access; claiming needs write |
| Guest sees it, host still shows `/dev/sda` | not a real claim; re-check the three tells |
| Windows offers to format the volume | decline unless you intend to erase it |
| Works, then vanishes after the board resets | it re-enumerated under a new VID:PID — see "Port vs. VID:PID" |

## Removing it again

```sh
./vm-usb.sh detach 3-1                                  # give it back to the host
sudo rm /etc/udev/rules.d/70-atmel-uc3-msc.rules        # drop the permission grant
sudo udevadm control --reload && sudo udevadm trigger --action=add --subsystem-match=usb
```

The host reclaims the device and `/dev/sda` reappears.

## Notes

- These rules live in `/etc/udev/rules.d/` (root-owned, outside the Stow tree), so they are
  **not** deployed by `stow` and not version-controlled. The rule text above is the only
  copy — reinstall it by hand after a fresh Arch install.
- Never pass through: the USB host controllers, the fingerprint reader (`27c6:6594`), or a
  disk the host has mounted.
- Related: `~/VMs/docs/usb-passthrough.md` (the tooling and VID:PID recipes),
  `tools/usb-helper.md` (host-side mounting), `system/storage.md`.
