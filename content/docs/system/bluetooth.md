---
title: "Bluetooth"
date: 2026-03-11
tags: ["system", "bluetooth"]
source: doc/pages/system/bluetooth.md
source_sha: 25e3bb5c7292
---

> Bluetooth management via bluetoothctl and blueman.

## bluetoothctl interactive

- Open interactive shell:
  `bluetoothctl`

- Inside bluetoothctl:
  ```
  power on
  scan on
  devices          # list discovered devices
  pair <MAC>
  connect <MAC>
  disconnect <MAC>
  trust <MAC>
  remove <MAC>
  show             # adapter info
  ```

- Quick one-liners:
  `bluetoothctl devices`
  `bluetoothctl show`
  `bluetoothctl scan on`

## Waybar

- Click bluetooth module → `blueman-toggle.sh` (opens blueman or toggles power)
- Blueman window opens floating near cursor (800x600)

## Troubleshooting

- Check bluetooth service:
  `systemctl status bluetooth`

- Restart service:
  `sudo systemctl restart bluetooth`

- Check connected devices:
  `bluetoothctl devices Connected`
