---
title: "Privilege elevation for Sway tools"
date: 2026-06-15
tags: ["tools", "security", "sudo"]
source: doc/pages/tools/usb-helper-elevation.md
source_sha: 0bbf2efc9869
---

A single, audited way for ecosystem tools to run privileged commands and prompt for the
password through **fuzzel** — without the password ever leaking and without giving another
local user a way in.

- `lib/sudo-askpass-fuzzel.sh` — the password prompt (a `SUDO_ASKPASS` helper).
- `lib/elevate.sh` — sourced library: `run_elevated`, `run_elevated_fresh`, `elevate_confirm`.
- `format-usb` — a real destructive tool (partition + format + set partition type)
  showing the safe pattern end to end; `set-partition-type` — a non-destructive sibling.

## The mechanism (and why it's the safe one)

It uses **sudo's askpass** feature. When a tool runs `sudo -A …` with `SUDO_ASKPASS`
pointing at our helper, sudo executes that helper (as *you*, never root) and reads the
password from its **stdout over a pipe**. Our helper is just `fuzzel --password`.

```
fuzzel (masked input)  ──stdout──▶  askpass helper  ──pipe──▶  sudo  ──▶  PAM
```

**Our handling** of the password keeps it off every channel we control:

- not in a command argument (`ps`/`/proc/<pid>/cmdline` show nothing) — it's not on any argv;
- not in an environment variable (`/proc/<pid>/environ`) — `SUDO_ASKPASS` holds only the
  *path* to the helper, not the secret;
- not in a file — there is **no temp file** at all (unlike a `sudo -S < file` design), and the
  askpass sets `ulimit -c 0` so a fuzzel crash can't dump it to an on-disk core;
- not in shell history — it's never typed at a shell.

> **Swap caveat (honest):** the secret is not written to disk *by us*, but it does pass
> through fuzzel, the askpass, and sudo/PAM as plaintext in *their* process memory, which is
> ordinary pageable memory (fuzzel does not `mlock` its input). Under memory pressure a page
> could reach swap. If that matters to you, use **encrypted swap** (the usual Arch default
> with an encrypted root). This is a property of your host, not something the tool can promise.

Other safety properties built into `elevate.sh`:

- **Commands run as argv**, `sudo -A -- "$@"` — never assembled into a string and `eval`'d,
  so an argument can't be reinterpreted as shell, and a `-`-leading argument can't be parsed
  as a sudo flag (`--` ends sudo's options).
- **The root environment is sanitized** — `secure_path` is set in Arch's `/etc/sudoers`, and
  `env_reset` is sudo's built-in default, so `PATH`/`LD_PRELOAD`/`IFS` tricks don't reach the
  privileged process.
- **No setuid script, no `NOPASSWD`, no long-lived elevated daemon or IPC socket** — there is
  nothing for another local user to call into. Each elevation is a fresh, user-initiated sudo.
- **Anti-tamper gate.** Before arming, `elevate.sh` verifies that the askpass helper — and
  `elevate.sh` itself — are regular files owned by you or root and not writable by group/other,
  with **every directory up to `/`** on the resolved path (and on the symlink's own path) also
  owned by you/root and not writable by others. It then hands sudo the **resolved** path, so a
  later symlink flip can't redirect it. If a different local user could overwrite or shadow the
  helper, they could steal your password — so the library refuses to arm.
  *Limit:* a script can't bootstrap trust in itself — if `elevate.sh` or the calling tool were
  *already* replaced (their directory was writable at some earlier time), the check runs the
  attacker's code. Install under a path only you can write (your `$HOME` is `0700`); the gate
  defends the "writable now" case, not a prior compromise.

## Threat model — what this does and does NOT protect against

**Protected:**

| Threat                                                   | Mitigation |
|----------------------------------------------------------|------------|
| Password visible to other processes via `ps`/cmdline     | never on argv |
| Password readable via `/proc/<pid>/environ`              | never in env |
| Password recoverable from a temp file / core dump        | no file; `ulimit -c 0` (swap caveat above) |
| Another **Unix user** reading your password              | different uid can't read your pipe/process memory |
| Another user swapping in a password-stealing askpass     | ownership + no-g/o-write on the helper, `elevate.sh`, and **every dir up to `/`** (resolved + symlink path); sudo gets the resolved path |
| Command/arg reinterpreted as shell or sudo flag          | argv + `--`, no `eval` |
| `PATH`/`LD_PRELOAD` hijack of the root process           | sudo `secure_path` + `env_reset` |
| A second local user invoking your elevated action        | no setuid/NOPASSWD/daemon to invoke |
| Fat-finger on a destructive target                       | `elevate_confirm` (type-to-confirm) |
| Target swapped between choose & act (TOCTOU)             | re-verify by stable id (serial + UUID), fail-closed if none |

**NOT protected (be honest about the limits):**

- **A malicious program running as *your own* user.** It can already do anything you can:
  log your keystrokes, read your files, spoof a fuzzel prompt, or reuse a cached sudo
  timestamp. This is a fundamental Unix boundary, not a flaw in this design. Mitigate by not
  running untrusted code as your user, using `run_elevated_fresh` for high-risk actions, and
  keeping your tool files non-writable by others (which the anti-tamper gate enforces for the
  askpass and `elevate.sh`, but cannot retroactively prove for a tool already tampered with).
- **Prompt spoofing.** Any program in your session can pop its own fuzzel asking for your
  password (polkit agents have the same exposure). Be suspicious of password prompts you
  didn't trigger.
- **An attacker who is already root**, or has **physical access** / a compromised compositor
  / an unlocked unattended session. Out of scope — at that point they are effectively you or
  the system.

## Install

This tool's `lib/` is deployed at `~/.local/bin/lib/` (from the dotfiles via GNU Stow).
The general rule: put `lib/` somewhere **you own and that is not writable by other users** —
`~/.local/lib/`, `~/.local/bin/`, or your dotfiles tree are all fine; **not** `/tmp` or any
world-writable dir.

```sh
chmod 755 lib/elevate.sh lib/sudo-askpass-fuzzel.sh   # executable, not group/other-writable
# the containing directory must also not be group/other-writable (a plain ~/… dir is fine)
```

`elevate.sh` enforces these at load time and refuses to arm otherwise; if a tool prints
*"NOT arming — askpass helper is … writable by others"*, fix the permissions.

You also need sudo authority. On Arch the usual path is `wheel` membership — but note the
package ships `/etc/sudoers` with the `%wheel ALL=(ALL:ALL) ALL` line **commented out**, so
you must both add yourself to `wheel` *and* enable that rule via `sudo visudo` (or drop a file
under `/etc/sudoers.d/`). No `NOPASSWD` rule is required or recommended — the password prompt
is what gates each elevation.

## Usage

```bash
SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
. "$SELF_DIR/lib/elevate.sh" || die "Elevation helper unavailable or unsafe — aborting."

run_elevated       systemctl restart foo          # prompt (or reuse a cached sudo timestamp)
run_elevated_fresh mkfs.ext4 -F /dev/sdb1          # ALWAYS re-prompt (-k); use for risky ops
run_elevated parted -s /dev/sdb mklabel gpt        # partitioning, etc.
```

`run_elevated` returns the command's exit status; check it and notify on failure (§4.1 of the
authoring guide). On cancel (Escape at the password prompt) sudo fails and the command does
not run.

### Caching policy

`run_elevated` honours sudo's normal credential cache (one prompt, then a short grace period).
The timestamp lives in the root-owned `0700` directory `/run/sudo/ts` — a *different* user
can't reuse it. For destructive or rarely-run actions, prefer `run_elevated_fresh`, which adds
`-k` so it always re-authenticates regardless of the cache.

### Destructive-action pattern (see `format-usb`)

1. Enumerate only safe targets (e.g. `TRAN=usb` — the system disk is unreachable), and skip
   in-use ones (mounted, or a disk with crypt/lvm/raid children).
2. Pick by **index** (`fuzzel --index`), never by typed free text.
3. `elevate_confirm "ERASE …" "<exact value>"` — the user types the target to proceed.
4. **Re-verify** the target by a *stable identity* (serial + partition/fs UUID) immediately
   before acting, and **fail closed** if no stable id is available — re-checking only the
   `/dev` path is not enough, since paths get reused.
5. `run_elevated_fresh …` to perform the privileged step.
6. Notify the result.

## Optional hardening: scope sudo to specific commands

Plain membership in `wheel` lets these helpers run *anything* as root (with your password) —
which is the same authority you have at a shell. To narrow a tool to *only* the commands it
needs, add a command-scoped drop-in (edit with `visudo` so it's validated; the file must be
root-owned `0440`):

```
# /etc/sudoers.d/usb-formatter   (created via: sudo visudo -f /etc/sudoers.d/usb-formatter)
benou ALL=(root) /usr/bin/mkfs.ext4, /usr/bin/mkfs.exfat, /usr/bin/mkfs.vfat
```

Keep the password requirement (no `NOPASSWD`) so the fuzzel prompt still gates each use.
This bounds the blast radius if a tool is ever tricked into running the wrong command.

## Why not polkit / pkexec?

`pkexec` is the polkit-native equivalent and sanitizes the environment even more
aggressively, but to show a *graphical* password dialog it needs a **running polkit
authentication agent** — and there isn't a simple way to make *fuzzel* be that agent (a real
agent is a D-Bus service implementing `org.freedesktop.PolicyKit1.AuthenticationAgent`).
(`pkexec` does have a built-in *textual* fallback agent, but it needs a tty and won't render
in a fuzzel/Sway keybinding context.) The `sudo -A` askpass route gives us the fuzzel prompt
we want with equivalent secret-handling guarantees. If you later run a polkit agent, prefer
`pkexec`/`udisksctl`/`systemctl --user` for actions that have a polkit action defined — they
often need no password at all (authoring guide §5.1).
