---
title: "Secure Boot"
date: 2026-03-11
tags: ["system", "secure-boot", "sbctl"]
source: doc/pages/system/secure-boot.md
source_sha: 46d4e4dddd14
---

> Secure Boot setup with sbctl. Run after first boot in UEFI Setup Mode.

## Setup (first time)

Requires UEFI in **Setup Mode** (erase all Secure Boot settings in BIOS).

```
pacman -S sbctl
sbctl status          # confirm: Setup Mode: enabled
sbctl create-keys
sbctl enroll-keys -m --firmware-builtin --tpm-eventlog
```

Flags used:
- `-m` / `--microsoft` — include Microsoft vendor certs (needed for Option ROMs, docks, etc.)
- `--firmware-builtin` — include OEM certs from dbDefault/KEKDefault
- `--tpm-eventlog` — include TPM event log checksums (skip if your device doesn't support it)

## Sign boot files

Check what needs signing:
```
sbctl verify
```

Sign all unsigned files (use `--save` to auto-sign on future kernel/bootloader updates):
```
sbctl sign --save /efi/EFI/BOOT/BOOTX64.EFI
sbctl sign --save /efi/EFI/Linux/arch-linux.efi
sbctl sign --save /efi/EFI/Linux/arch-linux-fallback.efi
sbctl sign --save /efi/EFI/systemd/systemd-bootx64.efi
```

## Verify after reboot

```
bootctl
```

Expected output:
```
Secure Boot: enabled (user)
TPM2 Support: yes
Measured UKI: yes
```

Also:
```
sbctl status    # should show: Secure Boot: enabled
```

## Sign fwupd (for firmware updates)

Required so fwupd can apply UEFI capsule updates:
```
sudo sbctl sign -s /usr/lib/fwupd/efi/fwupdx64.efi -o /usr/lib/fwupd/efi/fwupdx64.efi.signed
```

`-s` / `--save` adds it to the automatic hook so it's re-signed after fwupd updates.

## After kernel or bootloader update

sbctl's pacman hooks handle re-signing automatically if `--save` was used.

To manually re-sign everything:
```
sbctl sign-all
```

## Rotating Secure Boot keys

After re-enrollment or firmware update that changes PCR7, if things break:
1. Boot with LUKS passphrase
2. Re-enroll keys: `sbctl enroll-keys -m --firmware-builtin`
3. Re-sign: `sbctl sign-all`
