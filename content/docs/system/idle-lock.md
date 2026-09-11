---
title: "Idle and lock"
date: 2026-08-23
tags: ["system", "idle", "swayidle"]
source: doc/pages/system/idle-lock.md
source_sha: 969d2ed27478
---

> Swayidle timeouts, screen locking, and suspend behavior.

## Idle timeline

| Time            | Event                                                 | Power   |
|-----------------|-------------------------------------------------------|---------|
| 9m 30s (570s)   | Warning: "Screen will lock in 30 seconds"             | Any     |
| 10m (600s)      | Screen locks: `swaylock -f -i $lockpaper`             | Any     |
| 10m 30s (630s)  | Displays power off: `swaymsg "output * power off"`    | Any     |
| 30m (1800s)     | Suspend                                               | Battery |
| 90m (5400s)     | Suspend                                               | Any     |
| On activity     | Displays power back on: `swaymsg "output * power on"` | Any     |
| Before sleep    | Screen locks immediately                              | Any     |
| After resume    | Displays power back on: `swaymsg "output * power on"` | Any     |

On battery the machine suspends at 30m and never reaches the 90m entry. On AC the
30m entry is a no-op and the 90m entry catches it.

There is only one warning, at 570s, and that is deliberate. Warnings at 1770s and
5370s shipped until 2026-08-04, but both land *after* the 630s displays-off with the
screen locked, so they rendered into a powered-off panel and mako expired them 5s
later per `default-timeout`. Neither had ever been seen. Any new warning has to fire
before 630s to be worth adding.

## Why both "On activity" and "After resume"

They fire on different signals and neither covers the other:

- **`resume`** (attached to the 630s timeout) fires on **input-device** activity.
- **`after-resume`** fires on logind's resume-from-sleep signal.

The suspend timeouts land *after* the 630s displays-off, so the machine always
suspends with its outputs already powered down. If only `resume` existed, waking via
something that is not a sway input device — the power button, which goes to logind —
would resume the machine to a permanently black screen, because nothing would ever
run `output * power on`. That is exactly the 2026-08-03 incident: repeated power-button
presses did nothing and only a trackpad click brought the displays back.

On this machine the power button also cannot wake from s2idle at all (`/proc/acpi/wakeup`
has no `PWRB` entry — no wake GPE), so use the trackpad, keyboard, or lid. `after-resume`
is what makes any of those light the screens immediately rather than depending on which
device generated the wake. See [suspend-resume](/docs/system/suspend-resume/) for wake sources and the
Thunderbolt dock behaviour across sleep.

`power off` / `power on` are the current sway verbs; `dpms` is a deprecated alias.

## Every resume restarts the whole ladder

swayidle re-registers its idle notifications on logind's resume signal, so the clock
above restarts from zero on every wake — even a wake that produced no input and that
nobody asked for. Measured on 2026-08-04: three consecutive resume-to-suspend intervals
of **exactly 1:30:00**.

That is fine when a person woke the machine, and expensive when nothing did. A suspend
that bounces off a spurious wake costs a further 90 minutes of full-power awake time
before the ladder even tries again, which is how a machine left idle on AC came back
warm with 16 minutes of sleep out of 4h47. The wake source itself is a hardware
question — see [suspend-resume](/docs/system/suspend-resume/).

`if-unattended.sh` exists to shorten that penalty, and is **not wired into
`idle-daemon.sh`** — it stays inert until the wake-path checklist in
[suspend-resume](/docs/system/suspend-resume/) has passed. Wiring it in is one rung:

```
timeout 300 "$scripts/if-unattended.sh systemctl suspend"
```

It is inert during a normal idle period, because at 300s nothing is locked yet and
swayidle fires each timeout only once per idle period. It bites only when the ladder was
re-armed by a resume, and then only if all five of its preconditions hold: no kill-switch
file, swaylock running, no retry in the last 15 minutes, sway answering `swaymsg`, and at
least one output reporting `active` and `power`. Each one is there so that a machine which
cannot be woken is never suspended again — read the header comment before changing any of
them.

Two consequences worth knowing before enabling it:

- A manual `$mod+Escape` lock also becomes "suspend after 5 minutes of no input", on AC
  too. Use `idle-block.sh` for a long unattended job.
- `touch ~/.config/sway/no-idle-resuspend` disables the rung immediately — no edit, no
  reload. That is the escape hatch to reach for from a TTY.

## Manual lock

- Lock screen immediately:
  `$mod+Escape`
  or: `swaylock -f -i ~/.wallpaper/wall_dark.png`

## swaylock

- Lock wallpaper: `~/.wallpaper/wall_dark.png`
- `-f` flag: fork to background (non-blocking)

## Inhibiting idle

- Some apps automatically inhibit idle (e.g. video players via wayland idle-inhibit protocol)
- `systemd-inhibit --what=idle …` does **not** work against this ladder — see below
- To manually inhibit from a terminal, and the right tool for a long unattended job:
  `~/.config/sway/scripts/idle-inhibit.sh acquire <key>` / `release <key>` / `status`
- To pause swayidle outright (added for games, not bound to any key):
  `~/.config/sway/scripts/idle-block.sh start` / `stop`
  `~/.config/sway/scripts/idle-block.sh wrap <command>` (pauses for that command's lifetime)
  It SIGSTOPs / SIGCONTs the swayidle process — a reload restarts swayidle and clears a stuck pause

`systemd-inhibit --what=idle` does **not** stop this ladder, despite being the first
answer everywhere. swayidle drives every rung off sway's idle notification, not off
logind's idle state, so a systemd idle inhibitor leaves the lock and displays-off rungs
firing on schedule. Measured on 2026-08-14 with a real inhibitor held
(`systemd-inhibit --what=idle --who=doctest tail -f /dev/null`, confirmed present in
`systemd-inhibit --list`): a scratch `swayidle -w timeout 3` fired in 3 of 4 ten-second
trials. Under `idle-inhibit.sh` in the same conditions it fired in 0 of 4.

A parked swayidle is worse than no idle handling at all, which is why `wrap` traps
`EXIT INT TERM HUP` to restore it even when the wrapped command is killed. While stopped,
swayidle still holds its logind sleep inhibitor but cannot answer `PrepareForSleep`, so a
lid close suspends anyway once `InhibitDelayMaxUSec` (5s) runs out and `before-sleep`
never runs — the machine suspends **unlocked**. Check with `ps -o stat= -C swayidle`: `T`
means parked, `S` means healthy.

### idle-inhibit.sh — prefer this over SIGSTOP

`idle-inhibit.sh` sets sway's own per-window inhibitor (`swaymsg "[con_id=N] inhibit_idle
open"`) instead of touching the swayidle process. Sway then stops reporting the seat as
idle, so no rung fires, while swayidle keeps running normally and answers
`PrepareForSleep` — the unlocked-suspend failure mode above is simply not reachable. Sway
also drops the inhibitor by itself when the window closes, so a crashed job cannot leave
the machine permanently awake. That is what makes it safe to drive from automation,
which `idle-block.sh` is not.

- It targets the **focused** window at `acquire` time. Focus is the only usable selector:
  ghostty runs single-instance, so every ghostty window reports the same pid in
  `swaymsg -t get_tree` and pid cannot tell them apart. Which window holds it does not
  matter — one inhibitor suppresses idle for the whole seat.
- Holders are refcounted as files in `$XDG_RUNTIME_DIR/sway-idle-inhibit.d/`, so two
  concurrent jobs do not cancel each other's inhibitor. The last release clears it.
- Every path exits 0, including "no sway socket" and "no focused view". It runs as a
  Claude Code hook, where a non-zero exit surfaces an error into the session.
- `acquire` sweeps holder files older than 12h, so a `SIGKILL`ed job cannot pin the
  refcount forever. The real inhibitor is not at risk either way — sway released it when
  the window closed.

Releasing re-arms the ladder **from zero**, which is the property that makes it safe to
hold for hours: a job that finishes at 3am does not leave the machine awake until
morning, it leaves it locking ten minutes later on the normal schedule. Measured on
2026-08-14 with a scratch `swayidle -w timeout 5`: no idle event in 14s while held, and
the same rung firing immediately after release.

When testing any of this, note that a rung **not** firing proves very little — any stray
keypress or trackpad touch resets the idle clock and produces exactly the same silence.
A rung *firing* is the informative outcome, because noise cannot cause one. Run several
short trials and compare fire counts rather than trusting a single quiet window; a first
attempt here read as "systemd-inhibit suppresses swayidle" purely because both arms of
the comparison happened to be disturbed.

### Claude Code keeps the machine awake while it works

A long Claude Code run generates no input events, so the machine walked down the ladder
and suspended mid-task. Three hooks in `~/.claude/settings.json` drive `idle-inhibit.sh`,
each keyed on `session_id` so concurrent sessions refcount independently:

| Hook               | Action    | Why                                            |
|--------------------|-----------|------------------------------------------------|
| `UserPromptSubmit` | `acquire` | Fires on submit, so the window is focused      |
| `Stop`             | `release` | Claude finished its turn                       |
| `SessionEnd`       | `release` | Exit mid-turn, `/clear`, crash                 |

Each command is `jq -r '.session_id' | { read -r id; …; } 2>/dev/null || true` — piping
into `read` rather than `xargs`, which would split on spaces.

The inhibitor is held only while Claude is *working*, not for the whole session, so the
screen still locks normally while a session sits idle at the prompt. The cost of the
choice is that nothing locks during a long run, not just that nothing suspends: sway's
inhibitor suppresses the whole ladder and there is no way to suppress only the suspend
rungs through it. Gating just the suspend rungs on a busy flag was the alternative, and
was rejected because swayidle fires each timeout once per idle period — a skipped suspend
never re-arms, so the machine would stay awake until the next input anyway.

Hook edits are picked up by Claude Code's settings file watcher; `/hooks` shows what is
live and which file it came from. Nothing here requires a sway reload, a swayidle
restart, or a new terminal.

A turn that is **already running** when the hooks change is not covered, because its
`UserPromptSubmit` fired before they existed — a session working since before the edit
keeps walking down the ladder until its next prompt. Cover it by hand with its session id
(from `/status`, or the newest file under `~/.claude/projects/*/`), which its own `Stop`
hook then releases:

```sh
~/.config/sway/scripts/idle-inhibit.sh acquire <session-id>
```

Run it **from that session's window**: `acquire` binds to the focused container, so
running it elsewhere pins the inhibitor to the wrong window and it dies early if that
window closes. The inhibit is seat-wide either way, so this only matters for lifetime.

## Battery-aware suspend

- `~/.config/sway/scripts/on-battery.sh CMD...` runs `CMD` only when on battery
- Gates the 30m suspend, so it does not fire while plugged in
- Finds the adapter by walking `Mains`-type entries in `/sys/class/power_supply`,
  so USB-C PD sources (`type=USB`) are ignored
- Fails closed: if no adapter can be read it does nothing, so it can never suspend
  a machine that is on AC
- Check the current state: `~/.config/sway/scripts/on-battery.sh echo "on battery"`

## Swayidle service

- Swayidle is started from the sway config by one line:
  `exec_always ~/.config/sway/scripts/idle-daemon.sh`
- The timeouts live in that script, not in the sway config — see the warning below
- The script kills the previous daemon before starting a new one, so `$mod+Shift+c`
  applies timeout edits without stacking duplicates (verify with `pgrep -c swayidle` → `1`)
- It sends SIGCONT before SIGTERM, so a reload can also retire a daemon that
  `idle-block.sh start` left parked (a stopped process cannot act on SIGTERM)
- `-w` flag: wait for commands to finish before continuing

## Never put ";" in a sway exec line

Sway splits command lists on `;`, including inside `exec` / `exec_always`. Writing
the daemon inline as:

```
exec_always pkill -x swayidle; swayidle -w \
    timeout 600 'swaylock -f -i $lockpaper' \
    ...
```

parses as **two** sway commands: `exec_always pkill -x swayidle` runs and kills the
daemon, then the rest is rejected with `Unknown/invalid command 'swayidle'`. The
result is a machine with no lock at all — no idle lock, no displays-off, no suspend, and
no `before-sleep`, so opening the lid lands straight on an unlocked desktop. This
shipped in 2e086eb and is what `idle-daemon.sh` exists to prevent.

`sway --validate` does **not** catch it: `exec_always` is deferred, so the bad
fragment is only dispatched at run time, which validate never reaches.

### Checking that idle actually works

```sh
pgrep -c swayidle                       # must be 1
systemd-inhibit --list | grep swayidle  # must show a sleep/delay inhibitor
~/.config/sway/scripts/idle-inhibit.sh status   # must say "not held" when idle is expected
```

The inhibitor is the load-bearing one: no swayidle inhibitor means `before-sleep`
cannot fire, so lid-close suspends without locking. Sway logs config errors to its
own stderr, which is usually discarded, so a silently dropped daemon leaves no trace
— check these two commands after touching the idle config.

To check `after-resume` without waiting out the 10m30 timeout, reproduce the state the
machine actually suspends in and then wake it with the lid rather than the trackpad:

```sh
swaymsg "output * power off"
systemctl suspend
```

Open the lid — the displays must come back with no further input. Waking by keypress or
trackpad exercises the `resume` hook instead, so it passes either way and does not test
this.
