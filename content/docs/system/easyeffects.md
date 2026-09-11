---
title: "EasyEffects"
date: 2026-09-11
tags: ["system", "audio", "dsp"]
source: doc/pages/system/easyeffects.md
source_sha: d5dd64963653
---

> Global audio DSP for PipeWire — EQ, convolver, limiter. Autostarts with sway.

## What it does

Inserts an `easyeffects_sink` into the PipeWire graph and runs every output stream
through the `Base` preset:

  | Stage       | Setting                                                |
  |-------------|--------------------------------------------------------|
  | equalizer#0 | 10 bands, input-gain -2 dB, channels linked            |
  | convolver#0 | kernel `impulse-movie`, input-gain -2 dB, fully wet    |
  | limiter#0   | Herm Wide, threshold -0.5 dB, lookahead 5 ms           |

EQ curve (all Bell):

  | Freq | Gain | Freq | Gain |
  |------|------|------|------|
  | 32   | +4   | 1k   | -2   |
  | 64   | +2   | 2k   | +0   |
  | 125  | +1   | 4k   | +2   |
  | 250  | +0   | 8k   | +3   |
  | 500  | -1   | 16k  | +3   |

## Autostart

Started by sway, see `.config/sway/config`:
  `exec easyeffects --service-mode --hide-window`

Both flags are needed:

- `--hide-window` — without it the GUI window maps on login. `--service-mode` alone
  does NOT start headless, despite the name.
- `--service-mode` — keeps the DSP running after the GUI window is closed. Without it,
  closing the window kills the whole chain.

## Where the config lives

Tracked in the dotfiles repo, symlinked in by stow:

- Impulse responses: `~/.local/share/easyeffects/irs/` → `~/Dotfiles/.local/share/easyeffects/irs/`
- Presets: `~/.local/share/easyeffects/output/` → `~/Dotfiles/.local/share/easyeffects/output/`

Deliberately NOT tracked: `~/.config/easyeffects/db/*rc`. The app rewrites those
constantly (window geometry, preset-use counters) and they embed this machine's PCI
device names. `Base.json` already describes the whole chain and is fully portable.

Because `output/` is a directory symlink, presets saved from the GUI land straight in
the repo — check `git status` after tuning.

## Impulse responses

Five kernels, 1278 frames / 26.6 ms / 48 kHz 16-bit stereo, short tone-shaping
filters rather than room reverbs:

  `impulse-dynamic`  `impulse-game`  `impulse-movie`  `impulse-music`  `impulse-voice`

- Add a new one — drop the .wav/.irs in, then commit it:
  `cp foo.wav ~/.local/share/easyeffects/irs/foo.irs && cd ~/Dotfiles && git add -A .local/share/easyeffects`

## Commands

- List available presets:
  `easyeffects -p`

- Show currently loaded input/output presets:
  `easyeffects -s`

- Load a preset:
  `easyeffects -l Base`

- Toggle all effects on/off (A/B the sound):
  `easyeffects --bypass-toggle`

- Query bypass state (1 enabled, 2 disabled):
  `easyeffects -b 3`

- Open the GUI on the running service:
  `easyeffects`

- Quit the service entirely:
  `easyeffects -q`

- Confirm the filter is in the graph:
  `pw-cli ls Node | grep easyeffects`

## Fresh machine

After the first `stow`, `~/.config/easyeffects/db/` does not exist, so no preset is
applied even though the IRs and presets are present. Run once:
  `easyeffects -l Base`

The choice then persists in `easyeffectsrc` and is restored on every start.

## See also

`system/audio` for volume/mic/sinks, `system/pipewire` for the underlying stack.
