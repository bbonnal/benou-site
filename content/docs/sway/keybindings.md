---
title: "Sway keybindings"
date: 2026-08-03
tags: ["sway", "keybindings", "shortcuts"]
source: doc/pages/sway/keybindings.md
source_sha: 2e988f6ad42c
---

> All sway keybindings — $mod is Super (Mod4).

## Applications

- Open terminal:
  `$mod+t`

- Open browser (Firefox):
  `$mod+x`

- Open file manager (Thunar):
  `$mod+c`

- Open launcher (fuzzel):
  `$mod+Space`

- Open system manual:
  `$mod+Home`

## Window management

- Kill focused window:
  `$mod+q`

- Toggle floating:
  `$mod+f`

- Fullscreen:
  `$mod+y`

- Swap focus tiling/floating:
  `$mod+g`

- Focus parent container:
  `$mod+a`

- Lock screen:
  `$mod+Escape`

## Focus / Move

- Focus: `$mod+h/j/k/l` (left/down/up/right)
- Move window: `$mod+Shift+h/j/k/l`

## Layout

- Split horizontal: `$mod+b`
- Split vertical: `$mod+v`
- Layout stacking: `$mod+s`
- Layout tabbed: `$mod+w`
- Layout toggle split: `$mod+e`

## Scratchpad

- Send to scratchpad: `$mod+Shift+minus`
- Show scratchpad: `$mod+minus`

## Resize

- Resize: `$mod+Alt+h/j/k/l` (narrower/taller/shorter/wider)
- Steps 10px per press; hold to repeat

## Workspaces

- Switch to workspace 1–10: `$mod+1` … `$mod+0`
- Move container to workspace 1–10: `$mod+Shift+1` … `$mod+Shift+0`

## System / Media keys

- Volume mute (works on lock screen): `XF86AudioMute`
- Volume down 5%: `XF86AudioLowerVolume`
- Volume up 5%: `XF86AudioRaiseVolume`
- Mic mute: `XF86AudioMicMute`
- Brightness up 5%: `XF86MonBrightnessUp`
- Brightness down 5%: `XF86MonBrightnessDown`

## Screenshots

- Capture area (interactive): `Print`
- Capture full screen: `Shift+Print`
- Capture focused window: `Ctrl+Print`
- Pick color under cursor → clipboard: `$mod+Shift+Print`

## Config

- Reload sway + waybar: `$mod+Shift+c`
- Exit sway: `$mod+Shift+e`
