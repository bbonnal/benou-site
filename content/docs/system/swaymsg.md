---
title: "swaymsg"
date: 2026-03-11
tags: ["system", "sway", "debugging"]
source: doc/pages/system/swaymsg.md
source_sha: 0b368baa2064
---

> swaymsg debugging and inspection commands.

## Inspect

- List all inputs (keyboards, mice, touchpad, wacom):
  `swaymsg -t get_inputs`

- List all outputs (monitors):
  `swaymsg -t get_outputs`

- Full window tree (find app_id, titles):
  `swaymsg -t get_tree`

- Find app_id of a specific window:
  `swaymsg -t get_tree | grep -i app_id -A2 -B2`

- Find a specific window (e.g. pavucontrol):
  `swaymsg -t get_tree | grep -A10 "pavucontrol"`

- Get current config:
  `swaymsg -t get_config`

- Find swayidle in config:
  `swaymsg -t get_config | grep swayidle -n`

- Check scroll_factor:
  `swaymsg -t get_inputs | grep scroll_factor`

## Control

- Reload sway config + restart waybar:
  `swaymsg reload` (or `$mod+Shift+c`)

- Kill focused window:
  `swaymsg -t command kill`

- Move workspace to output:
  `swaymsg workspace 2 output "Lenovo Group Limited P24h-10 VTN45266"`

- Toggle DPMS (display on/off):
  `swaymsg output eDP-1 dpms off`
  `swaymsg output eDP-1 dpms on`

## Debugging window rules

To check what app_id/title a window has (for `for_window` rules):
```
swaymsg -t get_tree | grep -i app_id -A2 -B2
```
Or use `xprop` for XWayland windows (reports WM_CLASS instead):
```
xprop | grep WM_CLASS   # click the window
```
