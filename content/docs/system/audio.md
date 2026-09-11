---
title: "Audio"
date: 2026-09-11
tags: ["system", "audio", "pulseaudio"]
source: doc/pages/system/audio.md
source_sha: dc52101e5bf3
---

> Volume, microphone, and audio sink management.

## Hardware keys (work on lock screen)

- Toggle output mute: `XF86AudioMute`
- Volume down 5%: `XF86AudioLowerVolume`
- Volume up 5%: `XF86AudioRaiseVolume`
- Toggle mic mute: `XF86AudioMicMute`

## Scripts triggered by keys

- Volume change: `~/.config/sway/scripts/volume-notify.sh` (sends a notification)
- Mic mute toggle: `~/.config/sway/scripts/mic-notify.sh`

## Waybar controls

- Click pulseaudio module → output gain slider (`out-gain-slider.sh`)
- Right-click pulseaudio module → PulseAudio volume control (pavucontrol)
- Click mic module → mic gain slider (`mic-gain-slider.sh`)
- pavucontrol opens as a floating window (800x600) near cursor

## PulseAudio commands

- Set output volume to 50%:
  `pactl set-sink-volume @DEFAULT_SINK@ 50%`

- Increase volume 10%:
  `pactl set-sink-volume @DEFAULT_SINK@ +10%`

- Mute/unmute output:
  `pactl set-sink-mute @DEFAULT_SINK@ toggle`

- Mute/unmute mic:
  `pactl set-source-mute @DEFAULT_SOURCE@ toggle`

- List audio sinks:
  `pactl list sinks short`

- Switch default sink:
  `pactl set-default-sink <sink-name>`

## Audio sink switcher

- Waybar `custom/audio-sink` module shows current sink and updates every 5s
- Script: `~/.config/waybar/scripts/audio-sink.sh`

## EQ / effects

- Global EQ, convolver and limiter run in EasyEffects (autostarted by sway)
- See `system/easyeffects`
