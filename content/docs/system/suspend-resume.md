---
title: "Suspend and resume"
date: 2026-08-08
tags: ["system", "suspend", "s2idle"]
source: doc/pages/system/suspend-resume.md
source_sha: 282d97ffe064
---

> Wake sources, spurious wakes out of s2idle, the Thunderbolt dock across sleep, and the
> open items from the 2026-08-03 slow-resume incident. Idle timeouts and DPMS live in
> [idle-lock](/docs/system/idle-lock/).

## Machine

ThinkPad T14s Gen 6 AMD — `21M1000PMZ`, Ryzen AI 7 PRO 360, BIOS `R2NET42W 1.16` (2025-10-10).
Only `s2idle` is available (`cat /sys/power/mem_sleep` → `[s2idle]`); there is no S3 to fall
back to. Docked to a ThinkPad Thunderbolt 4 Dock driving 2× P24h-10 over DP-tunnel-in-USB4.

## The power button cannot wake this machine

```sh
cat /proc/acpi/wakeup    # lists SLPB and LID — there is no PWRB entry
```

No `PWRB` entry means the ACPI power button has no wake GPE, so it cannot bring the SoC out
of s0i3. This is firmware, not configurable from Linux — `PNP0C0C:00/power/wakeup` reads
`enabled` but that is the driver's own flag, not an armed wake source.

**Wake with the trackpad, the internal keyboard, or the lid.** All three are wakeup-enabled:

```sh
# what can actually wake the machine
for f in /sys/bus/*/devices/*/power/wakeup /sys/devices/platform/*/power/wakeup; do
  [ "$(cat "$f" 2>/dev/null)" = enabled ] && echo "$f"
done
```

Note the trackpad is `i2c-SYNA8022:00`. Devices on the dock cannot wake the machine once the
dock has dropped off the bus — which is exactly what happened on 2026-08-03, so the external
Keychron was not an option either.

Since 2026-08-03 the displays no longer depend on which device woke the machine — see the
`after-resume` hook in [idle-lock](/docs/system/idle-lock/).

## Spurious wakes from s2idle (2026-08-04) — open, wake source not yet named

Left idle on AC for an afternoon, the machine came back warm with the fans audible and
the screen merely locked. It had suspended on schedule every time; it just refused to
stay asleep.

```
17:29:33 suspend entry (s2idle)  ->  17:29:43 suspend exit   asleep 10s
18:59:43 suspend entry           ->  19:00:55 suspend exit   asleep 1m12s
20:30:56 suspend entry           ->  20:31:33 suspend exit   asleep 37s
22:01:33 suspend entry           ->  22:16:05 suspend exit   asleep 14m32s
```

Resume to next suspend is **exactly 1:30:00**, three times running: the 5400s rung fires,
the machine sleeps properly, something wakes it within seconds, and swayidle re-arms the
whole ladder from zero. Asleep 16 minutes out of 4h47. The sleep itself is not the
problem — `last_hw_sleep` was 865.7s against 872s of wall time (99.2%) and every
`failed_*` counter is 0. See [idle-lock](/docs/system/idle-lock/) for the ladder-restart behaviour.

With the lid closed the same wake produces a much tighter loop, driven by logind rather
than swayidle:

```
74 x "PM: suspend entry" in one boot
42 x "amd_pmc AMDI000A:00: Last suspend didn't reach deepest state"
14:43:26 entry -> 14:43:31 exit -> 14:43:57 entry -> 14:44:02 exit -> ...   31s period, ~85 min
```

`HandleLidSwitch=suspend` with `HoldoffTimeoutUSec=30s`, and logind reports
`Docked=false` — a USB-C/Thunderbolt dock is not an ACPI dock station, so
`HandleLidSwitchDocked=ignore` never applies no matter how many external displays are
attached. Every spurious wake is therefore followed 30s later by another lid-triggered
suspend. After a dozen rounds the platform stopped reaching s0i3 at all, which is where
most of the heat came from.

```sh
busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
  org.freedesktop.login1.Manager HandleLidSwitch HandleLidSwitchDocked \
  HoldoffTimeoutUSec Docked LidClosed
```

To break the lid loop before the wake source is found, the lever is a drop-in under
`/etc/systemd/logind.conf.d/` — outside this repo, and it trades away lid-close suspend.

### Naming the wake source

`/sys/power/pm_wakeup_irq` reads 9 — the ACPI SCI — so the wake arrives as a GPE, not as
a device MSI. That narrows it to something ACPI-signalled but does not identify it;
the rest needs root.

```sh
echo 1 | sudo tee /sys/power/pm_debug_messages
systemctl suspend
sudo dmesg | grep -iE "Resume caused by|wakeup source"
sudo grep -v "	0	" /sys/kernel/debug/wakeup_sources | sort -t$'\t' -k3 -rn | head

# or diff the GPE counters across one suspend
grep . /sys/firmware/acpi/interrupts/gpe[0-9A-F]* > /tmp/gpe.before
systemctl suspend
grep . /sys/firmware/acpi/interrupts/gpe[0-9A-F]* > /tmp/gpe.after
diff /tmp/gpe.before /tmp/gpe.after
```

**Leading suspect: the WWAN modem.** The Quectel RM520N-GL is torn down and re-enumerated
once per suspend cycle — `mmcli -L` reported `Modem/74` against 74 suspend entries — and
never comes back healthy: `mhi mhi1: Wait for device to enter SBL or Mission mode` with no
success line, then 370 x `MBIM error: Transaction timed out` in one boot. Its PCIe bridge
`0000:00:02.5` shows `wakeup_active_count=4153` against 75 for the Wi-Fi bridge.

```sh
nmcli radio wwan off     # then one long test suspend
grep . /sys/power/suspend_stats/*    # last_hw_sleep should ~= wall clock asleep
nmcli radio wwan on      # restore
```

Ruled out already: Wi-Fi (`iw phy0 wowlan show` → disabled, and NetworkManager
disconnects it before sleep), wake-arming systemd timers (none set `WakeSystem=true`),
and the Thunderbolt dock (no `thunderbolt` or `DPIA AUX` entries in the affected boot —
it was undocked).

**Not evidence, however tempting:** `i2c-SYNA8022:00` at `wakeup_active_count=212228`,
`serio0` at 5776, and `gpe07` at 153441. Those count every input report and every GPIO
interrupt during normal awake use, not wakes. `gpe07` is the AMD GPIO controller that
carries the touchpad IRQ.

### Wake-path checklist

Run this before enabling anything that increases the number of suspends per hour, three
times per row. Reproduce the state the machine actually suspends in — outputs already
powered down — or the test is easier than reality:

```sh
swaylock -f -i ~/.wallpaper/wall_dark.png
swaymsg "output * power off"
systemctl suspend
```

| Wake by           | Must happen                                                      |
|-------------------|------------------------------------------------------------------|
| trackpad          | screens light, swaylock takes the password, no second attempt    |
| internal keyboard | same                                                             |
| lid open          | same, with no further input — this is what `after-resume` is for |

Note the resume time for each; 2026-08-03 saw a ~17s dock-tree rebuild. If any row is
flaky, fix that path — do not compensate with a shorter suspend timeout. The
`if-unattended.sh` rung in [idle-lock](/docs/system/idle-lock/) stays unwired until all three pass.

## Open item 1 — check for a BIOS newer than 1.16

Wake-source arming lives in firmware, so a BIOS update is the only thing that could make the
power button work. Current BIOS dates from 2025-10-10.

```sh
fwupdmgr refresh
fwupdmgr get-upgrades
```

See [fwupd](/docs/system/fwupd/) for the Secure Boot signing prerequisites. Verify after:

```sh
cat /sys/class/dmi/id/bios_version   # currently R2NET42W
grep -c PWRB /proc/acpi/wakeup       # 0 today; 1 would mean the button became a wake source
```

## Open item 2 — BIOS settings so the dock survives sleep

On 2026-08-03 the dock fell off the bus during a 7-hour s2idle:

```
thunderbolt 0000:c5:00.5: 0:2: failed to reach state TB_PORT_UP. Ignoring port...
thunderbolt 0000:c5:00.5: 0:2: lost during suspend, disconnecting
```

First occurrence in 60+ days of journal. Because both monitors are DP-tunnelled through the
dock, the whole tree had to be rebuilt on resume (~17 s), and it came back on the *other*
controller — `0-2` on NHI0 became `1-2` on NHI1.

Settings to confirm in BIOS (F1 at boot):

| Menu                 | Setting                      | Want         | Why                                                        |
|----------------------|------------------------------|--------------|------------------------------------------------------------|
| Config → Thunderbolt | Thunderbolt BIOS Assist Mode | **Disabled** | Correct for Linux; the kernel drives the controller itself |
| Config → Power       | Always On USB                | **Enabled**  | Keeps the dock link powered during s0i3                    |
| Config → Power       | Charge in Battery Mode       | **Enabled**  | Same, when not on AC                                       |

If it recurs after that, capture a proper trace before filing anything — add
`thunderbolt.dyndbg=+p` to the kernel cmdline, reproduce a long sleep, then:

```sh
journalctl -k -b -g "TB_PORT_UP|lost during suspend"
```

## Open item 3 — the wedged empty Thunderbolt controller

When the dock migrates to NHI1, the now-empty NHI0 (`0000:c5:00.5`) is left in a failing
runtime-PM loop — roughly every 40 s it runtime-suspends, then `tb_domain_runtime_resume` →
`tb_ctl_start` → `tb_ring_start` trips:

```
thunderbolt 0000:c5:00.5: interrupt for TX ring 0 is already enabled
WARNING: drivers/thunderbolt/nhi.c:147 at ring_interrupt_active+0x255/0x300
thunderbolt 0000:c5:00.5: 0: timeout writing config space 2 to 0x1
```

Each iteration burns ~18 s in config-space timeouts. This is journal noise and wasted
wakeups, **not** a functional break — the dock works fine on NHI1. It is a
[known long-standing kernel bug](https://bugs.launchpad.net/bugs/2052411), not an Arch
regression.

Two ways to clear it:

```sh
# quiet it in place — safe because NHI0 has no devices attached.
# costs a little idle power, does not survive a reboot.
echo on | sudo tee /sys/bus/pci/devices/0000:c5:00.5/power/control

# or reboot: resets both controllers and re-attaches the dock to NHI0
```

Check whether it is currently looping:

```sh
journalctl -k -b -g "already enabled|timeout .* config space" --since "10 min ago"
```

## Confirming a suspend was healthy

The useful signal is hardware-sleep residency — it should be ≈ wall-clock time asleep:

```sh
grep . /sys/power/suspend_stats/*
```

`last_hw_sleep` is in microseconds. On 2026-08-03 it read 25,521.7 s against 25,526 s of wall
time — 99.98% in deep s0i3, all `failed_*` counters 0. That rules out the sleep itself and
points at wake sources or device re-enumeration instead.

Journal timestamps are misleading here: the console is suspended, so the entire
suspend+resume sequence is flushed at once and stamped with the *resume* time. Do not read
those bunched timestamps as durations — use `suspend_stats` and the events *after* resume.

```sh
# what the resume actually did, minus the noise
journalctl -b -k -o short-precise --since "<resume time>" | grep -viE "DPIA AUX failed|mtp-probe"
```

## Related

- [idle-lock](/docs/system/idle-lock/) — idle timeouts, DPMS, `before-sleep` / `after-resume`
- [fwupd](/docs/system/fwupd/) — firmware updates, Secure Boot signing
- [display](/docs/system/display/) — output layout and stable identifiers
- [journalctl](/docs/system/journalctl/) — log querying
