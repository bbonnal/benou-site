---
title: "Sway workspaces"
date: 2026-03-11
tags: ["sway", "workspaces", "monitors"]
source: doc/pages/sway/workspaces.md
source_sha: 0433993c9275
---

> 3-monitor workspace layout and assignment rules.

## Monitor layout

```
[eDP-1: 1920x1200]  [P24h-10 VTN45266: 2560x1440]  [P24h-10 VTN45265: 2560x1440]
  Laptop (left)           Middle (primary)                  Right
  pos 0,0                 pos 1920,0                        pos 4480,0
```

## Workspace assignments

- Workspace 1 → Laptop display (eDP-1)
- Workspaces 2–9 → Middle monitor (Lenovo P24h-10 VTN45266)
- Workspace 10 → Right monitor (Lenovo P24h-10 VTN45265)

## Waybar icons

| Workspace | Icon |
|-----------|------|
| 1 | 󰌢 (keyboard/laptop) |
| 2 | (terminal) |
| 3 | (terminal) |
| 4 | (terminal) |
| 5 | (terminal) |
| 6 | 󰆧 (document) |
| 7 | 󰎸 (music) |
| 8 | 󰎻 (music) |
| 9 | 󰎾 (music) |
| 10 | 󰍹 (monitor) |

## Tips

- All workspaces are persistent (always visible in bar even when empty):
  `persistent-workspaces: { "1": [], ... "10": [] }`

- If a monitor is disconnected, workspaces fall back to eDP-1 (disp1).
