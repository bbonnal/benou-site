---
title: "PipeWire"
date: 2026-09-11
tags: ["system", "audio", "pipewire"]
source: doc/pages/system/pipewire.md
source_sha: 40b7245e68a9
---

> PipeWire / WirePlumber audio stack — troubleshooting and management. For the DSP chain see `system/easyeffects`.

## Restart audio stack

Fixes most audio glitches (crackling, lost output, HDMI no sound):

- Restart everything:
  `systemctl --user restart pipewire pipewire-pulse wireplumber`

- Restart only WirePlumber:
  `systemctl --user restart wireplumber`

## Inspect

- List sinks (outputs):
  `pactl list sinks short`

- List sources (inputs/mics):
  `pactl list sources short`

- Full sink details (sample rate, format, active port):
  `pactl list sinks`

- PipeWire graph status:
  `wpctl status`

- PipeWire node info by ID:
  `pw-cli info <node-id>`

- Dump full PipeWire graph (pipe to grep):
  `pw-dump | grep -A20 "HDMI4"`

## HDMI audio

HDMI audio sink name pattern: `alsa_output.pci-0000_c4_00.1.HiFi__HDMI4__sink`

- Set volume on HDMI sink:
  `pactl set-sink-volume alsa_output.pci-0000_c4_00.1.HiFi__HDMI4__sink 50%`

- Test HDMI audio:
  `paplay --device=alsa_output.pci-0000_c4_00.1.HiFi__HDMI4__sink /usr/share/sounds/alsa/Front_Center.wav`

- Set active card profile:
  `pactl set-card-profile alsa_card.pci-0000_c4_00.1 HiFi`

## Microphone

- Check mute state:
  `pactl get-source-mute @DEFAULT_SOURCE@`

- List sources with mute:
  `pactl list sources | grep -A10 "alsa_input" | grep "Mute:"`

## Logs

- WirePlumber logs (recent):
  `journalctl --user -u wireplumber -n 50 --no-pager`

- PipeWire logs:
  `journalctl --user -u pipewire -n 50 --no-pager`

## Audio sink switcher

- Waybar `custom/audio-sink` shows current sink
- Switch sink via: `~/.config/waybar/scripts/audio-sink.sh`
- Right-click volume in waybar → pavucontrol for full control
