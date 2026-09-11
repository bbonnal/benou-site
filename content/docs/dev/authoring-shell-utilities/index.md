---
title: "Authoring shell utilities"
date: 2026-06-15
tags: ["dev", "bash", "shell", "conventions"]
source: doc/pages/dev/authoring-shell-utilities.md
source_sha: 6cdab4bf1732
---

A practical, opinionated guide for building small **bash** utilities for this system, so
every tool behaves consistently and survives real-world failure. It is written to be read
by **humans** picking up a tool and by **AI agents** extending the ecosystem.

It is *generic where it can be* — the structure, robustness rules, and conventions apply
to any tool. Some sections are conditional: **secrets (§5)** matter only to tools that
handle them, **Wayland verbs (§4.6)** only to tools that drive the desktop, and so on.
The first concrete tool built against it is `usb-helper` (deployed at
`~/.local/bin/usb-helper`; see its guide `../tools/usb-helper.md`); use it as a worked
example, not as a template for scope.

> **How to use this guide.** Skim §1 for the shape of a tool, copy [`utility-template.sh`](utility-template.sh),
> then keep §2 (robustness) and Appendix B (gotcha table) open while you work. Give each
> new tool its own `CLAUDE.md` per §9, linking back here.

---

## 0. The environment contract

Every tool may assume this baseline and should target it explicitly:

| Thing            | Assumption                                                            |
|------------------|-----------------------------------------------------------------------|
| OS               | Arch Linux (rolling) — recent coreutils, util-linux, GNU grep         |
| Shell            | `bash` ≥ 4.3 (associative arrays + namerefs). Not `sh`/`dash`/`zsh`.  |
| Session          | Wayland under **Sway**; tools are launched from keybindings           |
| User I/O         | **fuzzel** (menus / text / password) — *there is no terminal*         |
| Messages         | **mako** via `notify-send` (libnotify)                                 |
| Init / services  | systemd; user services & transient jobs via `systemctl --user` / `systemd-run --user` |
| Privilege        | **polkit** authorizes *actions* for the active session (often no password) |
| Paths            | XDG base dirs (`$XDG_CONFIG_HOME`, `$XDG_RUNTIME_DIR`, …)              |

These are *this system's* chosen tools. The portable lessons — centralize I/O, treat
Escape as cancel, pick by index not text, parse structure not prose — transfer to any
menu/notifier you might swap in.

**The single most important consequence:** a tool bound to a key has **no controlling
terminal**. `echo`/`printf` to stdout/stderr is invisible to the user. Therefore:

> **Every outcome the user must see — success, failure, "nothing to do" — is a
> `notify-send` notification, not terminal output.** Keep `echo … >&2` only as a secondary
> breadcrumb for when you run the tool by hand while debugging.

---

## 1. Anatomy of a utility

Copy `utility-template.sh`. Every tool has the same backbone, in this order:

1. **Shebang + strict mode** — `#!/usr/bin/env bash` then `set -euo pipefail`.
2. **Interpreter guard** — fail loudly if bash is too old (or got run by `sh`).
3. **Constants** — app name, timeouts, XDG-based config path.
4. **Single-instance lock** *(if the tool mutates state)* — see §7.2.
5. **Dependency check** — verify every external command up front; fail with a notification.
6. **Cleanup trap** — register an `EXIT` (+ signal) trap before anything creates state.
7. **Helpers** — `notify`, `die`, `need`, config loaders.
8. **Core logic** — small, single-purpose functions. Guard preconditions and empty results
   (§3.4) before showing a menu.
9. **`main()`** — wire it together; call `main "$@"` as the last line.

Same landmarks in the same places across every tool means anyone — human or AI — can open
any tool and navigate it.

---

## 2. Robustness: surviving `set -euo pipefail`

This is where most shell bugs live. Turn the safety flags on, then write code that is
actually correct under them. Each gotcha below states its fix **once**; Appendix B is the
quick-reference table.

```bash
set -euo pipefail
#  -e          exit on any command failure (with exceptions, below)
#  -u          referencing an unset variable is an error (catches typos)
#  -o pipefail a pipeline fails if ANY stage fails, not just the last
```

### 2.1 The `-e` exemption rule (memorize this)

`set -e` does **not** trigger when the failing command is: the **condition** of
`if`/`while`/`until`; any command in a `&&`/`||` list **except the last**; negated with `!`;
or inside `(( ))`/`[[ ]]` used as a test. Everything else that returns non-zero aborts.
Every gotcha below is a corollary.

### 2.2 A bare command-substitution assignment aborts on failure

```bash
data=$(some_command)          # if some_command fails, the script dies HERE, silently
```
Capture in an `if` so failure becomes a *handled* error with a user-facing message:
```bash
if ! data=$(some_command); then die "some_command failed"; fi
```
**Inverse trap:** any *declaration builtin* — `local`, `declare`, `readonly`, `export`,
`typeset` — masks the command's exit status with its own, so `set -e` will *not* catch a
failure. If you need the failure caught, split it: `local data; data=$(cmd)`.

### 2.3 A function whose last statement is a false `&&`

```bash
maybe() { do_setup; [[ -n "$x" ]] && y=$x; }   # x empty -> returns 1 -> aborts a bare caller
```
Use the always-exit-0 inverse, or an explicit `return 0`:
```bash
[[ -z "$x" ]] || y=$x          # "do it unless empty"; exit status 0 either way
```

### 2.4 Arithmetic returns non-zero when the result is 0

`(( expr ))` exits non-zero when `expr` is `0`:
```bash
(( i++ ))                      # post-increment of 0 returns the old value 0 -> abort!
```
Safest: `i=$((i + 1))`. Alternatives: `((i++)) || true`, or `((++i))` *when the result
can't be 0*. `(( ))` is fine in any `if`/`while` **condition** (exempt position).

### 2.5 `-u` with maybe-unset variables and arrays

Reference possibly-unset values with a default: `"${VAR:-}"`, `"${MAP[$key]:-}"`,
`"${ARR[@]:-}"` (the array form matters on bash < 4.4, which trips on an empty
`"${arr[@]}"`).

### 2.6 `pipefail` + a tool that "fails" on no match

`grep` exits 1 on no match; `pipefail` then fails the pipeline and `set -e` aborts:
```bash
match=$(printf '%s\n' "$text" | grep -o 'pattern' || true)   # || true: no-match is OK here
```
Prefer a pure-bash match when you can (no external dialect to depend on, §4.2):
`[[ "$text" =~ pattern ]] && match="${BASH_REMATCH[0]}"`.

### 2.7 `while read` drops a final unterminated line

`read` returns non-zero at EOF, so a file whose last line lacks a newline loses that line:
```bash
while IFS= read -r line || [[ -n "$line" ]]; do … done < file   # || …: recover the last line
```

### 2.8 `set -e` does **not** reach inside command substitution / subshells

```bash
x=$( cmd1; cmd2 )              # cmd1 failing does NOT abort; only cmd2's status counts
```
errexit isn't reliably inherited into `$( … )` or `( … )`. Validate inside the subshell, or
run the steps as separate statements in the parent.

### 2.9 Cleanup that always runs: `EXIT` + signal traps

A `RETURN` trap does **not** fire when `set -e` aborts the function or a signal arrives —
exactly when you most need cleanup (e.g. a temp file holding a secret). An `ERR` trap is
also wrong: it isn't inherited into functions/subshells without `set -E`, and it doesn't
guarantee a single cleanup on every exit path. Use an **`EXIT`** trap, plus signal traps
that exit so the EXIT trap runs:
```bash
TMPFILES=()                              # state the trap will clean
cleanup() { local f; for f in "${TMPFILES[@]:-}"; do [[ -e "$f" ]] && rm -f "$f"; done; return 0; }
trap cleanup EXIT
trap 'exit 130' INT TERM HUP             # -> triggers the EXIT trap
```
Have the trap reference a **global** you update (not a value baked in at trap-set time), and
end the cleanup function on a zero status so it's safe under `set -e`.

### 2.10 Quote everything; prefer `[[ ]]` and `printf`

Quote every expansion (`"$var"`, `"${arr[@]}"`, `"$(cmd)"`). Use `[[ … ]]` over `[ … ]`
(no word-splitting; `==`, `=~`). Use `printf` over `echo` for anything non-trivial
(`printf '%s'` adds no trailing newline — important for secrets and for menu lines).

---

## 3. Talking to the user (a GUI with no terminal)

### 3.1 Notifications — wrap `notify-send`

Centralize it so every tool notifies identically, and so option-injection is impossible:
```bash
NOTIFY_TIMEOUT=3000
APP_NAME="My Tool"
notify() {                               # notify SUMMARY BODY
    # `--` stops option parsing: a body/label starting with '-' can't be read as a flag.
    notify-send -t "$NOTIFY_TIMEOUT" -a "$APP_NAME" -- "$1" "$2" || true
}
```
- `|| true` so a flaky daemon can't abort the tool via `set -e`.
- `-a "$APP_NAME"` groups a tool's notifications and lets mako rules target them.
- **Persistence is a mako setting, not an urgency.** Contrary to dunst, mako does **not**
  auto-stick `critical`; stickiness comes from `default-timeout` and any `[urgency=…]`
  config section. To make a fatal error persist regardless of config, pass `-t 0`
  (no expiry) explicitly. `-u critical` only changes urgency/grouping/style.
- **Replace a notification in place** (progress, status that supersedes itself): capture its
  id and reuse it. You must ask for the id with `-p`/`--print-id`, then pass it to
  `-r`/`--replace-id`:
  ```bash
  id=$(notify-send -p -a "$APP_NAME" -- "Working…" "")
  # …later…
  notify-send -r "$id" -a "$APP_NAME" -- "Done" "ok"
  ```
- **One-tap confirm without fuzzel:** `choice=$(notify-send -A 'ok=Confirm' --wait …)` prints
  the chosen action id on stdout (mako supports actions; `--wait` blocks until dismissed).
  Good for yes/no; fuzzel is still right for lists and password entry.

### 3.2 Menus and input — `fuzzel`

`fuzzel --dmenu` reads newline-separated choices on stdin and prints the chosen line.
- `--index` — print the **index** of the choice, not its text. Prefer it: pick
  `items[index]` directly instead of parsing the displayed line back into data (fragile the
  moment a label contains spaces). **The menu lines and your backing array must stay
  strictly parallel — same order and count.** So: strip newlines from each label (one line
  per item), and **de-duplicate before building both** — sources routinely emit repeats
  (e.g. one Wi-Fi SSID seen on several APs/bands). When entries share a display name, carry a
  unique key (BSSID, UUID, device path) in the parallel array and resolve via that.
- `--accept-nth=N` *(fuzzel ≳ 1.11)* — with tab-separated columns, return field *N* of the
  chosen line. A clean alternative to `--index` when items have a hidden id column.
- `--password[=CHAR]` — masked input; use for secrets (§5).
- `--prompt "…  "` — label the input (trailing spaces give breathing room).
- `--dmenu0` — NUL-separated input (use when items can contain newlines).

**Escape / no selection:** fuzzel exits **non-zero**. Treat it as "user cancelled":
```bash
choice=$(printf '%s\n' "$items" | fuzzel --dmenu --index --prompt "Pick  ") || exit 0
[[ "$choice" =~ ^[0-9]+$ ]] || exit 0    # defensive: ignore unexpected output
```
A trailing newline on the input is a line *terminator*, not an extra blank entry — the
correct, safe form; don't "fix" it away (some readers drop the last item without it).

### 3.3 Slow operations have no spinner

If a step can take more than ~1 s (a hardware scan, a network probe, a sync), the user
clicks the keybind and sees *nothing* — feels broken, invites a second launch. Fire a status
notification first, then replace it with the result (§3.1's `-p`/`-r`):
```bash
id=$(notify-send -p -a "$APP_NAME" -- "Scanning…" "")
results=$(slow_scan)                     # e.g. nmcli dev wifi list --rescan yes (~9s)
notify-send -r "$id" -a "$APP_NAME" -- "Found" "$(wc -l <<<"$results") networks"
```
For genuinely long or fire-and-forget work, detach it (§7.5) so the keybind returns at once.

### 3.4 Guard the empty / disabled state

Before popping a menu, check the obvious preconditions and emit a *specific* notification
instead of an empty fuzzel: "Wi-Fi is off", "No networks found", "No USB devices". This is
the "nothing to do" outcome from §0 — make it explicit, not a blank list.

### 3.5 Make errors visible

Because there's no terminal, the failure branch of every external call ends in a `notify`,
and the body should carry the captured command output (§4.1) so the user sees *why*.

---

## 4. Talking to the system

### 4.1 Capture output (including stderr); branch on exit codes that mean something

```bash
if ! output=$(some_command 2>&1); then
    notify "$APP_NAME" "Failed: $output"
    return 1
fi
```
`2>&1` folds stderr into the captured string so error text reaches the notification. When a
command's **exit codes carry meaning**, branch on them for a better message — `nmcli`, for
instance, distinguishes not-found / timeout / auth failure; "Wrong password?" reads far
better than a raw daemon string.

### 4.2 Prefer structured output; never parse human prose

Tool wording is localized and changes between versions — parsing it is the most common
source of silent breakage. Prefer machine/JSON modes and `jq`:

- JSON: `lsblk -J`, `findmnt -J`, `ip -j`, `pactl -f json`, `swaymsg -t get_tree`.
- Bare values: `systemctl show -p ActiveState --value <unit>`.

Worked example (domain-neutral): to learn a unit's state, ask
`systemctl show -p ActiveState --value foo`; don't grep `systemctl status` prose. (Storage
analogue: `findmnt -fnro TARGET <dev>` for a mountpoint, not the mounter's "Mounted X at Y."
line.)

**Not every tool offers JSON.** NetworkManager (`nmcli`) has no JSON mode — use its stable
machine modes: `-t/--terse`, `-g/--get-values FIELD`, `-f/--fields` to pin columns. Treat
those as the structured contract, not the default human table.

**Delimited machine output still needs care.** `nmcli -t` separates fields with `:` *and*
backslash-escapes a literal `:` inside a value (an SSID `my:net` arrives as `my\:net`).
Splitting naively on `:` cuts the value in half — the network-tool version of "wrong device
acted on" (§4.3). Split on *unescaped* separators only, or sidestep it by pulling one field
at a time with `-g FIELD`.

If you *must* parse free text, force a stable locale (`LC_ALL=C cmd`) and guard the parse
with `|| true` (§2.6). Don't assume a specific `grep`/`sed`/`awk` dialect is present — flags
vary across implementations. Fewer text-parsing assumptions ⇒ more portable.

### 4.3 Build identifiers from canonical sources

Don't hand-assemble paths/keys from fragments. Ask the tool for the canonical value. *(E.g.
storage: a decrypted LUKS node is named `dm-0` but its real node is `/dev/mapper/luks-…`;
use lsblk's `PATH` column instead of `"/dev/$name"`.)* Hand-built identifiers break on the
edge cases.

### 4.4 Read many fields at once; avoid the pipe-subshell trap

Calling `jq`/`lsblk -o` once **per field per item** forks a process each time. Extract a
row in one pass and read it:
```bash
while IFS=$'\t' read -r a b c; do … done < <(jq -r '.items[] | [.a,.b,.c] | @tsv')
mapfile -t names < <(jq -r '.items[].name')          # slurp a column into an array
```
**Correctness, not just speed:** `cmd | while read …` runs the loop in a **subshell**, so
variables it sets are lost after the pipe. Use process substitution `while read …; do …;
done < <(cmd)` (as above) so assignments survive.

### 4.5 `jq -e`

`jq -e` sets a non-zero exit when the output is `null`/`false`/empty — handy for presence
checks (`if v=$(jq -e '.x' …); then …`). But a *bare* `jq -e` aborts under `set -e` exactly
like grep-no-match — guard with `|| true` or use it as an `if` condition.

### 4.6 Wayland / Sway verbs (for tools that drive the desktop)

Generic building blocks — combine as needed:
- **Window/workspace state:** `swaymsg -t get_tree | jq …` (focus, geometry, app_id);
  act with `swaymsg '[app_id="…"] focus'`.
- **Clipboard:** `wl-copy` / `wl-paste` (`wl-copy` forks a server to hold the selection;
  let it).
- **Screen capture:** `grim` (+ `slurp` for a region). `slurp` exits **non-zero** on Escape,
  just like fuzzel (§3.2) — treat it as cancel.

---

## 5. Privilege and secrets

> **For running elevated commands, use the shared helper, not ad-hoc `sudo`.** `lib/elevate.sh`
> provides `run_elevated` / `run_elevated_fresh` (sudo askpass → fuzzel prompt; the password
> never touches argv/env/disk) plus an anti-tamper gate and `elevate_confirm`. Full mechanism
> and threat model: **`../tools/usb-helper-elevation.md`**. The rest of this section is the
> underlying reasoning.

### 5.1 Avoid `sudo` when polkit can authorize the action

polkit authorizes the active local session to perform many *actions* with **no password** —
but it authorizes the *action*, it does **not** hand you a *data secret* (a Wi-Fi PSK, a
LUKS passphrase); you still collect those (§5.2). Reach for the privilege-aware client
before scripting `sudo`:
- Reliably passwordless for the active session: `udisksctl` on **removable** media,
  `systemctl --user`.
- polkit-gated and **may prompt** depending on local rules — check, don't assume:
  `loginctl` power actions, system-scope `systemctl`, NetworkManager changes via `nmcli`.
- D-Bus clients (`busctl`, `gdbus`, `bluetoothctl`) inherit whatever polkit action the target
  method declares — they're not a generic password bypass.

### 5.2 When you genuinely need a secret

Collect it via fuzzel and hand it over without it touching argv, env, or persistent disk:
```bash
PASSWORD_FILE=""                                   # global, cleaned by the EXIT trap (§2.9)
collect_secret() {                                 # collect_secret [PROMPT] -> sets $PASSWORD_FILE
    local secret
    secret=$(fuzzel --dmenu --password --prompt "${1:-Password}  ") || return 1
    [[ -z "$secret" ]] && return 1
    PASSWORD_FILE=$(mktemp "${XDG_RUNTIME_DIR:-/dev/shm}/mytool.XXXXXX") || return 1
    chmod 600 "$PASSWORD_FILE"
    printf '%s' "$secret" > "$PASSWORD_FILE"        # printf: no trailing newline
}
# Use:  sudo -S cmd < "$PASSWORD_FILE"      (sudo -S reads the password from stdin)
#       udisksctl … --key-file "$PASSWORD_FILE"   (when a tool wants a key FILE)
```
**Secret hygiene:**
- **Never put a secret on the command line.** `ps` exposes argv to other processes. If a tool
  only accepts a secret as an argument (e.g. `nmcli dev wifi connect … password …`), prefer
  writing it into a mode-600 connection profile / keyfile (NetworkManager's own store, or one
  under `$XDG_RUNTIME_DIR`) and activating *that*. If you truly must pass it on argv, record
  that as an accepted limitation in the tool's `CLAUDE.md`.
- **RAM-backed dir.** `$XDG_RUNTIME_DIR` is a per-user **0700** tmpfs — preferable to the
  world-writable, sticky-bit (mode **1777**) `/dev/shm`; fall back to `/dev/shm` only if
  unset, and always `chmod 600` the file regardless.
- **Mode 600**, **no trailing newline** (`printf '%s'`), **cleaned immediately** after use
  *and* via the EXIT trap — never a `RETURN` trap (§2.9).
- `shred` on tmpfs is **best-effort only** (tmpfs can be swapped; there's no stable on-disk
  block to overwrite). Don't claim it "securely erases." The real protections are: small,
  mode 600, per-user RAM dir, deleted at once.

---

## 6. Configuration

### 6.1 Location and optionality

```bash
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/mytool/config"
```
Config is **optional**: a tool must work with sensible defaults if absent. Ship a
`config.example` and document the format.

### 6.2 Choose the simplest format that fits

- **JSON** → parse with `jq` (consistent with §4; ideal when the tool already uses `jq`).
- **INI / `key = value`** → parse in pure bash (idiom below).
- **Sourcing a bash file** is easiest to read but means **arbitrary code execution** on load.
  Only for a file the user fully controls — never anything fetched or shared — and say so
  loudly in the docs.

### 6.3 The pure-bash INI idiom

```bash
while IFS= read -r line || [[ -n "$line" ]]; do      # || … : keep a final unterminated line (§2.7)
    line="${line%%#*}"                                # strip from first '#' to EOL (comment)
    line="${line#"${line%%[![:space:]]*}"}"           # strip leading whitespace
    line="${line%"${line##*[![:space:]]}"}"           # strip trailing whitespace
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^\[.*\]$ ]] && { section="$line"; continue; }   # [section] header
    key="${line%%=*}"; val="${line#*=}"               # split on the FIRST '='
    # …trim key/val the same way, then store…
done < "$CONFIG_FILE"
```
The `${var#"…"}` / `${var%"…"}` pairs remove a computed prefix/suffix; with `[![:space:]]`
globs they strip surrounding whitespace without spawning `sed`. **Caveat:** the comment strip
treats *any* `#` as a comment start, so a value can't contain a literal `#`. If a tool needs
that (a URL fragment, a token), drop or restrict that line.

---

## 7. Conventions and reuse

### 7.1 Standard helpers

```bash
notify() { notify-send -t "$NOTIFY_TIMEOUT" -a "$APP_NAME" -- "$1" "$2" || true; }
log()    { printf '%s\n' "$*" >&2; }                                        # stderr breadcrumb
die()    { log "$1"; notify "$APP_NAME" "$1"; exit "${2:-1}"; }             # breadcrumb + notify + exit
need()   { command -v "$1" &>/dev/null || die "Missing dependency: $1"; }   # one dependency
```
The dependency check is just `need` in a loop (the template does this) — and because `die`
also writes to stderr, a missing `notify-send` is still reported when you run the tool by
hand. Config-lookup helpers can take an **associative array by name** via a nameref so one
function serves many maps:
```bash
get() { local -n _m="$1"; printf '%s' "${_m[$2]:-}"; }                      # get ARRAY_NAME KEY
```

### 7.2 Single-instance locking

A key-bound tool is trivially launched twice (double-tap, key repeat, holding the chord).
Two instances racing on the same state — same device, same secret file, same notification id
— is a real bug class. Self-lock with `flock`; the lock releases automatically when the
script exits (the fd closes), so it composes with the EXIT trap and needs no cleanup:
```bash
exec {LOCKFD}>"${XDG_RUNTIME_DIR:-/tmp}/mytool.lock"
flock -n "$LOCKFD" || exit 0          # another copy holds it -> exit quietly
```
Add it to any tool that *mutates* state; pure read-then-display tools can skip it.

### 7.3 Argument parsing

`main "$@"` is passed through even when unused, to leave room for flags. When you add them,
use `getopts` so every tool's flags look the same (reset `OPTIND` with `local OPTIND` if you
parse inside a function):
```bash
usage() { printf 'Usage: %s [-v] [-n NAME]\n' "${0##*/}"; }
verbose=0 name=""
while getopts ':vn:h' opt; do
    case $opt in
        v) verbose=1 ;;
        n) name=$OPTARG ;;
        h) usage; exit 0 ;;
        \?) die "Unknown option: -$OPTARG" ;;
        :)  die "Option -$OPTARG needs a value" ;;
    esac
done
shift $((OPTIND - 1))
```

### 7.4 Library vs copy-paste

For a handful of tools, **copy-paste** the ~15 lines of header + `notify`/`die`/`need` into
each: zero coupling, each tool is self-contained and movable. If the ecosystem outgrows that,
promote the shared bits to `lib/common.sh` and `source` it — but then **traps can clobber**:
a second `trap … EXIT` *replaces* the first. The convention: a single owner registers the
EXIT trap and it drains a shared `TMPFILES` array (as the template does); a sourced lib must
not install its own competing EXIT trap. Start copy-paste; graduate deliberately.

### 7.5 Long-running / detached work

To run something slow without blocking the keybind (and to give it its own cgroup, timeout,
and journal), launch it as a transient user unit:
```bash
systemd-run --user --scope --quiet some_long_job        # detached, survives the launcher
systemd-run --user --scope -p RuntimeMaxSec=30 some_job # with a timeout
```
Pair this with the progress-notification pattern (§3.3) when the user needs feedback.

### 7.6 Exit codes & `--help`

`0` = success or clean user-cancel; non-zero = a real failure (already notified). Accept
`-h|--help` and print one screen of usage to **stdout** (the one place terminal output is
correct). Prefer **idempotent** actions and re-query state rather than assuming it.

---

## 8. Testing without the hardware or the GUI

A tool talks to the world only through external commands, so you can exercise the *entire*
flow by replacing those commands with stubs earlier on `PATH`. This catches the runtime bugs
`bash -n` can't (set -e aborts, bad quoting, cleanup leaks).

```bash
T=$(mktemp -d); mkdir -p "$T/bin"

cat > "$T/bin/notify-send" <<'EOF'   # log the WHOLE argv line; assert with grep
#!/usr/bin/env bash
printf 'NOTIFY %s\n' "$*" >> "$CALL_LOG"
EOF

cat > "$T/bin/fuzzel" <<'EOF'        # return a SEQUENCE of answers, one per call
#!/usr/bin/env bash
# STUB_ANSWERS = newline-separated answers; pop one per invocation via a counter file.
n=$(< "$STUB_N" 2>/dev/null || echo 0); echo $((n+1)) > "$STUB_N"
sed -n "$((n+1))p" "$STUB_ANSWERS"
EOF

chmod +x "$T"/bin/*
CALL_LOG="$T/calls.log" STUB_N="$T/n" STUB_ANSWERS="$T/ans" PATH="$T/bin:$PATH" bash ./mytool.sh
```

- **Log argv as one line** (`"$*"`), don't re-extract a "body" field — that's the fragile
  text-parsing the guide warns against, and it bites when a body contains `-- `.
- **Multi-prompt tools** (pick, then password) call fuzzel more than once; a single canned
  answer never exercises the second prompt. Return a **sequence** (as above) so the whole
  flow runs.
- Test: the **happy path**, **every failure branch** (stub a command exiting non-zero — assert
  it notifies and exits cleanly, not silently), **cleanup** (after a mid-op failure, assert no
  temp/secret files leak: `find "$XDG_RUNTIME_DIR" -name 'mytool.*'` empty), and
  **cancellation** (a stub exiting non-zero → clean exit).
- Also run `bash -n mytool.sh`; and `shellcheck mytool.sh` if installed (it may not be —
  `pacman -S shellcheck`).

---

## 9. Documentation conventions (human + AI)

Every tool gets a **`CLAUDE.md`** next to it (AI agents auto-load it; humans read it first),
structured the same way across the ecosystem:

1. **What it is** — one paragraph.
2. **Target environment** — the §0 baseline + anything tool-specific.
3. **Dependencies table** — package → command → why.
4. **How it works** — a walkthrough that references **function names, never line numbers**
   (line numbers rot on the next edit; names don't). A small ASCII call-tree helps.
5. **Robustness invariants** — the non-obvious rules the code relies on (which traps, which
   `set -e` guard, why an identifier is queried not built). This is what stops the next editor
   or AI from reintroducing a fixed bug.
6. **Known limitations** — intentional trade-offs, written as decisions, not bugs.
7. A link back to this guide.

Inline comments follow one rule: **explain the *why* and the genuinely tricky bits; don't
teach bash basics.** Language fundamentals live in Appendix A, linked once — not repeated in
every file.

---

## 10. New-utility checklist

- [ ] `#!/usr/bin/env bash` + `set -euo pipefail` + interpreter-version guard.
- [ ] Single-instance `flock` (if the tool mutates state).
- [ ] Dependency check (`need` in a loop) failing via `notify`.
- [ ] `EXIT` (+ `INT TERM HUP`) cleanup trap registered before any state is created.
- [ ] All user-visible outcomes go through `notify`; errors include captured output; slow
      steps show progress (§3.3); empty/disabled state is guarded (§3.4).
- [ ] No human-prose parsing; structured/machine output; identifiers from canonical fields.
- [ ] Secrets (if any) via fuzzel → mode-600 file in `$XDG_RUNTIME_DIR`, EXIT-trap cleanup,
      never on argv.
- [ ] No `sudo` if a polkit/`--user` path exists.
- [ ] Config optional, under `$XDG_CONFIG_HOME`, with a shipped `*.example`.
- [ ] Every expansion quoted; `[[ ]]` over `[ ]`; reviewed against Appendix B.
- [ ] `bash -n` clean; `shellcheck` clean (if installed); PATH-stub test of happy + failure +
      cleanup + cancel paths (sequence stub for multi-prompt tools).
- [ ] A `CLAUDE.md` per §9, linking here.

---

## Appendix A — bash primer (link target for tools)

Tools link here instead of re-explaining the language inline.

- **`set -euo pipefail`** — exit on error / error on unset vars / fail pipelines on any stage.
  See §2 for staying correct under it.
- **`local`** — variable scoped to the current function. `local -n ref=NAME` is a *nameref*
  (alias to the variable named in `NAME`); good for passing arrays by name.
- **`declare -A M`** — associative array (map). `M[k]=v` sets; `"${M[k]:-default}"` reads.
- **`$(cmd)`** — command substitution. **`<<< "$v"`** — here-string (feed `$v` to stdin).
- **`< <(cmd)`** — process substitution: feed a command's output as a file/stdin *without* a
  pipe, so a `while read` loop runs in the current shell (§4.4).
- **`"${v:-x}"`** — `v`, or `x` if unset/empty. **`"${v:+x}"`** — `x` only if `v` non-empty.
- **`${v#p}`/`${v##p}`** — strip shortest/longest *prefix* glob `p`; **`${v%p}`/`${v%%p}`** —
  same for *suffix* (the §6.3 trim idiom).
- **`[[ … ]]`** — test: `-f`, `-n`/`-z`, `==`, `=~` (captures in `BASH_REMATCH`).
- **`trap CMD EXIT`** — run `CMD` whenever the shell exits, for any reason.
- **`mapfile -t arr < <(cmd)`** — read a command's lines into array `arr`.
- **`getopts`** — POSIX short-option parser; `OPTARG`/`OPTIND`; reset with `local OPTIND` in a
  function.
- **`jq -r`** — raw output. `.a // ""` = field or `""`; `select(p)` filters; `[.a,.b] | @tsv`
  = tab-separated row; **`jq -e`** = non-zero exit on null/false/empty (§4.5). `def f: …;`
  defines a reusable filter.
- **`$XDG_CONFIG_HOME`** (`~/.config`), **`$XDG_RUNTIME_DIR`** (per-user 0700 tmpfs, for
  runtime/secret files).

## Appendix B — gotcha quick-reference

| Symptom                                            | Cause                                  | Fix |
|----------------------------------------------------|----------------------------------------|-----|
| Script dies silently mid-run                       | bare `x=$(cmd)` failed under `set -e`  | capture in `if ! x=$(cmd); then …` (§2.2) |
| Failure not caught despite `set -e`                | `local x=$(cmd)` masks cmd status      | split: `local x; x=$(cmd)` (§2.2) |
| Function aborts caller unexpectedly                | last line is a false `&&`              | `[[ -z x ]] \|\| …` or `return 0` (§2.3) |
| Dies on a loop counter                             | `((i++))` returns old value `0`        | `i=$((i+1))` / `((i++)) \|\| true` (§2.4) |
| `unbound variable` error                           | `-u` on a maybe-unset value/array      | `"${v:-}"`, `"${arr[@]:-}"` (§2.5) |
| Crash when something legitimately isn't found      | `grep`/`jq -e` no-match + `pipefail`   | `… \|\| true`; prefer structured query (§2.6, §4.5) |
| Last config line ignored                           | `while read` drops unterminated line   | `while … read -r l \|\| [[ -n "$l" ]]` (§2.7) |
| First step's failure ignored inside `$( … )`       | errexit not inherited into subshell    | validate inside, or separate statements (§2.8) |
| Temp/secret file left behind after an error        | used a `RETURN`/`ERR` trap             | `EXIT` + signal traps (§2.9, §5.2) |
| Loop variables empty after a `cmd \| while read`   | pipe runs the loop in a subshell       | `while read …; do …; done < <(cmd)` (§4.4) |
| Works in your locale, breaks elsewhere             | parsing translated tool output         | structured output / `LC_ALL=C` (§4.2) |
| SSID/value cut in half                             | split on a separator that's escaped    | split unescaped only / `nmcli -g FIELD` (§4.2) |
| Wrong device/target acted on                       | hand-built identifier from fragments   | use the tool's canonical field (§4.3) |
| Notification with a `-`-leading body misbehaves    | option injection into `notify-send`    | `notify-send … -- "$s" "$b"` (§3.1) |
| Selected the wrong / a duplicate menu item         | re-parsed text, or non-unique entries  | `fuzzel --index`, de-dup, parallel key (§3.2) |
| Fatal error vanishes after a few seconds           | assumed `-u critical` is sticky (dunst)| `-t 0`, or a mako `[urgency=critical]` rule (§3.1) |
| User thinks a slow tool hung                       | no feedback during a multi-second op   | progress notify (`-p` then `-r`) (§3.3) |
| Two instances clobber shared state                 | no single-instance guard               | `flock -n` self-lock (§7.2) |

## Appendix C — notes for AI agents extending the ecosystem

- **Read the tool's `CLAUDE.md` and this guide before editing.** Honor the "robustness
  invariants"; if you must break one, say so explicitly and update the list.
- **Verify, don't assume.** Confirm a command/flag exists in *this* environment
  (`command -v`, `--help`) and that a version-sensitive feature is present (an lsblk column, a
  fuzzel flag, a notify-send option, a mako behavior) before relying on it. Notification and
  daemon behavior in particular differ between mako and dunst — check, don't recall.
- **Match the house style:** the §1 backbone order, the `notify`/`die`/`need` helpers,
  function-referenced docs, comments that explain *why* not *what*, compact over verbose.
- **Test through stubs (§8)** before declaring something works; exercise failure and cleanup
  paths, and multi-prompt sequences — not just the happy path. Report what you actually ran.
- **Keep it generic where it can be.** A new tool copies another's *structure*, never its
  domain logic.
