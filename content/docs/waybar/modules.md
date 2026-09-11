---
title: "Waybar modules"
date: 2026-03-11
tags: ["waybar", "modules", "statusbar"]
source: doc/pages/waybar/modules.md
source_sha: 676d5e797fa5
---

> Waybar module layout and click actions.

## Layout

```
[workspaces] [scratchpad] [window title]    [clock]    [tray] [cpu] [mem] [net] [vol] [sink] [mic] [bt] [bat] [arch]
       LEFT                                  CENTER                        RIGHT
```

## Module details

### sway/workspaces
- Shows workspace icons (Nerd Font)
- All 10 workspaces always visible (persistent)
- Click to switch workspace

### custom/scratchpad
- Shows scratchpad window count
- Click to cycle through scratchpad windows
- Script: `~/.config/waybar/scripts/scratchpad.sh`
- Updates every 1 second

### sway/window
- Shows focused window title (max 50 chars)

### clock
- Format: `YYYY-MM-DD HH:MM:SS`
- No tooltip

### cpu
- Format: ` {usage}%`
- Updates every 5 seconds
- Hover for per-core breakdown

### memory
- Format: `󰍛 used/total GB`
- Updates every 5 seconds

### network
- WiFi: ` SSID (signal%)`
- Ethernet: ` interface`
- Disconnected: `⚠ Disconnected`

### pulseaudio (output volume)
- Format: `icon volume%`
- Scroll: adjust volume ±5%
- Left-click: output gain slider (`out-gain-slider.sh`)
- Right-click: open pavucontrol (`pavu-toggle.sh`)

### custom/audio-sink
- Shows current audio sink name
- Script: `~/.config/waybar/scripts/audio-sink.sh`
- Updates every 5 seconds

### custom/mic
- Shows mic status (muted/active + level)
- Script: `~/.config/waybar/scripts/mic-status.sh`
- Left-click: mic gain slider (`mic-gain-slider.sh`)
- Updates every 2 seconds

### bluetooth
- Shows: ` connected` or ` off`
- Left-click: toggle bluetooth menu (`blueman-toggle.sh`)

### battery
- Icons: `     ` (empty → full)
- Warning at 30%, critical at 10%
- On update: `battery-notify.sh` (sends notification when low)
- Updates every 60 seconds

### tray
- System tray with 30px spacing between icons

### custom/arch
- Arch Linux  icon
- Left-click: power menu (`power-menu.sh`)
