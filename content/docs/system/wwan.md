---
title: "5G modem (WWAN)"
date: 2026-03-11
tags: ["system", "wwan", "modemmanager"]
source: doc/pages/system/wwan.md
source_sha: c731693fdd91
---

> 5G/LTE modem setup — Quectel RM520N-GL on Lenovo T14s.

## Hardware

- Modem: Quectel RM520N-GL
- Kernel driver: `mhi-pci-generic`
- Primary port: `wwan0mbim0` (use MBIM, not plain `wwan0`)
- ModemManager plugin: `quectel`
- Device ID: `1eac:1007`

## Setup (first time)

### 1. Install and enable ModemManager

```
sudo pacman -S modemmanager
sudo systemctl enable --now ModemManager NetworkManager
```

### 2. FCC unlock (required — modem won't come online without this)

The FCC lock is a software lock from Lenovo that prevents the modem from going online until an unlock sequence is sent. Required on Lenovo/Dell/HP laptops.

```
sudo mkdir -p /etc/ModemManager/fcc-unlock.d
sudo ln -s /usr/share/ModemManager/fcc-unlock.available.d/1eac:1007 \
           /etc/ModemManager/fcc-unlock.d/1eac:1007
sudo systemctl restart ModemManager
```

### 3. Verify modem is detected

```
mmcli -L             # list modems
mmcli -m 0           # details on modem 0
mmcli -m 0 | grep -i state
mmcli -m 0 | grep -i "primary port"
```

### 4. Enable modem and configure

```
sudo mmcli -m 0 --enable
sudo mmcli -m 0 --set-primary-sim-slot=1
sudo mmcli -m 0 --set-preferred-mode="allowed:4g,5g;preferred:5g"
```

Check SIM info:
```
mmcli -i 0
```

### 5. Create NetworkManager connection

```
nmcli connection add type gsm ifname wwan0mbim0 con-name sunrise apn internet
nmcli connection up sunrise
```

### 6. Verify connection

```
mmcli -m 0 | grep state       # should show: state: connected
nmcli device status            # should show: wwan0mbim0  gsm  connected
```

## Daily use

- Connection is managed by NetworkManager, reconnects automatically
- To bring up manually: `nmcli connection up sunrise`
- To check status: `nmcli device status`
- To disconnect: `nmcli connection down sunrise`

## Troubleshooting

- Modem stuck in low-power/locked state → check FCC unlock symlink exists
- Modem not detected → `sudo systemctl restart ModemManager`
- Connection drops → `sudo systemctl restart ModemManager NetworkManager`
- Check MM logs: `journalctl -u ModemManager -f`
- Check connection logs: `journalctl -xe NM_DEVICE=wwan0mbim0`
- `lsmod | grep -E 'qmi_wwan|cdc_mbim'` — verify kernel modules loaded
