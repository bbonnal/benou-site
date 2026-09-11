#!/usr/bin/env bash
#
# <tool-name>.sh — <one-line description>.
#
# Starter skeleton for a system shell utility. See docs/authoring-shell-utilities.md
# for the reasoning behind every section here; this file is the backbone you copy.
#
# FLOW: <describe the user-facing flow in one or two lines>
#
# DEPENDENCIES: <cmd (package) — why>, ...
#
# USAGE: ./<tool-name>.sh            (or bind in sway: bindsym $mod+x exec /path/to/<tool>.sh)

set -euo pipefail
#  -e exit on error · -u error on unset vars · -o pipefail fail a pipeline on any stage.
#  Stay correct under these: see "Robustness" in docs/authoring-shell-utilities.md (§2).

# ---- interpreter guard ------------------------------------------------------
# Associative arrays need bash 4; namerefs (local -n) need 4.3. Fail clearly if older
# (or if the script was started with sh/dash, where BASH_VERSINFO is unset).
if [ -z "${BASH_VERSINFO:-}" ] || ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 3))); then
    echo "<tool-name>: bash 4.3+ required" >&2
    exit 1
fi

# ---- constants --------------------------------------------------------------
APP_NAME="<Tool Name>"                                   # notification app name (grouping)
NOTIFY_TIMEOUT=3000                                      # notification lifetime, ms
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/<tool-name>/config"

# ---- single-instance lock (opt in: uncomment if this tool MUTATES state) ----
# Stops a double-launch (key repeat / double-tap) racing on shared state. The lock
# releases automatically when the script exits (the fd closes) — no cleanup needed.
# exec {LOCKFD}>"${XDG_RUNTIME_DIR:-/tmp}/<tool-name>.lock"
# flock -n "$LOCKFD" || exit 0

# ---- helpers ----------------------------------------------------------------
# There is no terminal: every user-visible outcome is a notification (§0).
notify() {                                               # notify SUMMARY BODY
    # `--` stops option parsing so a '-'-leading body can't be read as a flag.
    notify-send -t "$NOTIFY_TIMEOUT" -a "$APP_NAME" -- "$1" "$2" || true
}
log()  { printf '%s\n' "$*" >&2; }                       # stderr breadcrumb (visible when run by hand)
die()  { log "$1"; notify "$APP_NAME" "$1"; exit "${2:-1}"; }              # breadcrumb + notify + exit
need() { command -v "$1" &>/dev/null || die "Missing dependency: $1"; }    # one dependency

# ---- dependency check -------------------------------------------------------
# List ONLY the commands THIS tool uses (a notify-only tool needs neither fuzzel nor jq).
# `need` -> die -> log + notify, so a missing dep is reported on stderr even when the
# missing one IS notify-send.
for cmd in fuzzel notify-send jq; do need "$cmd"; done

# ---- cleanup trap -----------------------------------------------------------
# Register BEFORE creating any state. EXIT fires on normal exit AND on set -e aborts;
# the signal trap exits so the EXIT trap runs (a RETURN/ERR trap would NOT — §2.8).
TMPFILES=()
cleanup() {
    local f
    for f in "${TMPFILES[@]:-}"; do [[ -n "$f" && -e "$f" ]] && rm -f "$f"; done
    return 0                                             # end zero so it's set -e-safe
}
trap cleanup EXIT
trap 'exit 130' INT TERM HUP

# ---- optional config --------------------------------------------------------
# Must work with sane defaults if the file is absent. Pick the simplest format that
# fits (JSON via jq / the INI idiom below). Do NOT `source` untrusted config.
declare -A CONFIG
load_config() {
    [[ -f "$CONFIG_FILE" ]] || return 0
    local line key val
    while IFS= read -r line || [[ -n "$line" ]]; do      # || …: keep last unterminated line
        line="${line%%#*}"                               # strip comments
        line="${line#"${line%%[![:space:]]*}"}"          # strip leading whitespace
        line="${line%"${line##*[![:space:]]}"}"          # strip trailing whitespace
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^\[.*\]$ ]] && continue            # flat key=value: ignore [section] headers
        key="${line%%=*}"; val="${line#*=}"
        key="${key#"${key%%[![:space:]]*}"}"; key="${key%"${key##*[![:space:]]}"}"
        val="${val#"${val%%[![:space:]]*}"}"; val="${val%"${val##*[![:space:]]}"}"
        [[ -z "$key" ]] || CONFIG["$key"]="$val"
    done < "$CONFIG_FILE"
}

# ---- core logic -------------------------------------------------------------
# Replace with the tool's real work. Keep functions small and single-purpose.
# Pattern for an external action: capture output (incl. stderr), notify on failure.
do_something() {
    local output
    if output=$(some_command 2>&1); then
        notify "$APP_NAME" "Done."
    else
        notify "$APP_NAME" "Failed: $output"
        return 1
    fi
}

# ---- entry point ------------------------------------------------------------
main() {
    load_config
    do_something
}

main "$@"
