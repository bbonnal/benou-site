---
title: "Sway appearance"
date: 2026-08-03
tags: ["sway", "appearance", "colors"]
source: doc/pages/sway/appearance.md
source_sha: 9dd8957154d9
---

> Window borders, gaps and the focus color ramp.

## Borders and gaps

- Border style: `default_border pixel 5` — a frame only, no titlebar
- Inner gaps: 5px, outer gaps: 5px
- `smart_gaps on` — a lone window on a workspace gets no gaps
- Exceptions: the `yad` Mic Gain / Out Gain sliders pin `border pixel 2`

Gaps show the wallpaper, so every border is drawn against `wall_light.png`
(average `#547A7F`, range `#356E7B`…`#6E9AA1`). Border colors have to clear
that range to be visible.

## Focus color ramp

Perceived lightness (L) rises monotonically with focus, so the brightest
frame on the desktop is always the focused window:

    class              frame      L    meaning
    ---------------------------------------------------------------
    focused            #cbdcdb   215   the one window you are in
    focused_inactive   #4F7A84   110   last focus on another output
    unfocused          #0f1c1f    24   everything else
    urgent             #8BB2B5   167   demanding attention

`focused` is near-white because it is the only palette color that clears the
wallpaper. `focused_inactive` sits *on* the wallpaper tone deliberately — the
demoted tier should blend into the gaps.

## The five color fields

    client.<class> <border> <background> <text> <indicator> <child_border>

- `child_border` — the visible frame under `default_border pixel`. This is the
  field that does the work. Omit it and it silently inherits `background`.
- `text` / `background` — only render on tabbed and stacked titlebars
  (`$mod+w` / `$mod+s`). Invisible with `pixel` borders.
- `border` — the 1px outline around a titlebar. Also invisible with `pixel`.
- `indicator` — marks the edge where the next split will open, on the focused
  container only. Set to `#8BB2B5`, a teal notch on the near-white frame.

## Tuning

- Frame too loud: `default_border pixel 5` → `pixel 3`
- Focus still ambiguous: set `focused_inactive` identical to `unfocused`, so
  the desktop has two states instead of three
- Need a much stronger cue: `default_border normal 3` turns on titlebars
  everywhere — a filled colored bar with text, at ~25px per window

## Palette

There is no shared colorscheme file. The palette is hand-duplicated across
`.config/sway/config`, `.config/waybar/style.css`, `.config/mako/config` and
`.config/fuzzel/fuzzel.ini`. The nearest thing to a canonical definition is
the `@define-color` block at the top of waybar's `style.css`:

    bg-dark     #0f1c1f   background
    fg-light    #ffffff   foreground text
    primary     #4F7A84   primary accent
    secondary   #669299   secondary accent
    tertiary    #8BB2B5   tertiary / highlight
    muted       #8e9a99   muted / disabled

`#cbdcdb` is sway-only. `#669299` is not used by sway. Changing a color means
editing all four files.
