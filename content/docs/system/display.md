---
title: "Display"
date: 2026-03-11
tags: ["system", "display", "brightness"]
source: doc/pages/system/display.md
source_sha: 42ccee3ab35b
---

> Brightness control and monitor layout.

## Brightness keys

- Brightness up 5%: `XF86MonBrightnessUp`
- Brightness down 5%: `XF86MonBrightnessDown`
- Script fired: `~/.config/sway/scripts/brightness-notify.sh`

## Manual brightness control

- Set brightness to 50%:
  `brightnessctl set 50%`

- Increase by 10%:
  `brightnessctl set +10%`

- Decrease by 10%:
  `brightnessctl set 10%-`

- Get current brightness:
  `brightnessctl get`

## Monitor layout

```
[eDP-1: 1920x1200 @ 60Hz]  [P24h-10 VTN45266: 2560x1440 @ 60Hz]  [P24h-10 VTN45265: 2560x1440 @ 60Hz]
  pos 0,0                     pos 1920,0                             pos 4480,0
```

- Total width: 7040px

## sway output commands

- List outputs:
  `swaymsg -t get_outputs`

- Toggle output off/on:
  `swaymsg output eDP-1 dpms off`
  `swaymsg output eDP-1 dpms on`

- Move workspace to output:
  `swaymsg workspace 1 output eDP-1`

## Wallpaper

- Light wallpaper (day): `~/.wallpaper/wall_light.png`
- Dark wallpaper (lock screen): `~/.wallpaper/wall_dark.png`
- All outputs use the same wallpaper: `output * bg $wallpaper fill`
