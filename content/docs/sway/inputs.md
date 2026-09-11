---
title: "Sway inputs"
date: 2026-03-11
tags: ["sway", "input", "keyboard"]
source: doc/pages/sway/inputs.md
source_sha: 7fb10a147a1a
---

> Input device configuration: keyboard layouts, touchpad, wacom tablet.

## Keyboard

- Layout: `ch_benou_full` (custom Swiss layout with two variants)
- Variant 1 — `fr_code`: coding-optimized (symbols on AltGr)
- Variant 2 — `fr_typing`: typing-optimized (accents easier)
- Toggle between variants: `Alt+Shift`
- Caps Lock remapped to Ctrl: `ctrl:nocaps`

- Key repeat delay: 300ms
- Key repeat rate: 100 keys/sec

## Unicode input (in any app)

- Insert a unicode character by codepoint:
  `Ctrl+v` then `u` then hex code (e.g. `f488`) — works in GTK apps
- For longer codepoints:
  `Ctrl+v` then `U` then `0f0322`

## Touchpad (libinput)

- Tap to click: enabled
- Natural scroll: enabled
- Disable while typing (dwt): enabled
- Scroll method: two-finger
- Pointer acceleration: 0.5

## Mouse (pointer)

- Scroll factor: 3.0 (faster scroll)

## Wacom Intuos PT M 2 Pen

- Device: `1386:830:Wacom_Intuos_PT_M_2_Pen`
- Mapped to: Middle monitor (P24h-10 VTN45266)

## Focus behavior

- `focus_follows_mouse no` — focus does NOT follow mouse movement
