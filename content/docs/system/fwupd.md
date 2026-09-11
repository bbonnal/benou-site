---
title: "fwupd"
date: 2026-03-11
tags: ["system", "firmware", "uefi"]
source: doc/pages/system/fwupd.md
source_sha: 149bb1a88554
---

> Firmware updates via fwupdmgr (LVFS). Covers BIOS, EC, Thunderbolt, dock.

## Setup

```
sudo pacman -S udisks2 fwupd
sudo systemctl enable --now fwupd.service
```

Fwupd must be signed for Secure Boot (run once after sbctl setup):
```
sudo sbctl sign -s /usr/lib/fwupd/efi/fwupdx64.efi -o /usr/lib/fwupd/efi/fwupdx64.efi.signed
```

`/etc/fwupd/fwupd.conf`:
```ini
[fwupd]
EspLocation=/efi
[uefi_capsule]
DisableShimForSecureBoot=true
```

## Workflow

```
sudo fwupdmgr refresh --force     # sync metadata from LVFS
fwupdmgr get-devices              # list all detected firmware targets
fwupdmgr get-updates              # check available updates
sudo fwupdmgr update              # apply all updates
```

After reboot:
```
fwupdmgr get-history              # verify what was applied and when
```

## Typical update targets (T14s + dock)

- System Firmware (BIOS)
- Embedded Controller
- Thunderbolt Controller
- Lenovo docking station (via USB-C, must be powered and directly connected)

## Docking station not detected

```
fwupdmgr get-devices | grep -i dock
```

- Ensure dock is connected directly (not via hub)
- Ensure dock is powered on
- Then rerun `sudo fwupdmgr update`

## Notes

- BIOS updates require a reboot; Thunderbolt/dock updates apply live
- Updating BIOS may invalidate Secure Boot PCR state — re-sign with sbctl after
- Lenovo firmware is on LVFS and updates automatically via fwupd
