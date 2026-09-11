#!/usr/bin/env bash
#
# audit.sh — compare ~/Dotfiles/doc/pages against the published Hugo site, then
# scan every not-yet-published page for anything that must not go online.
#
# FLOW: inventory each dotfiles doc page (missing / stale / synced / orphaned),
#       then pattern-scan the missing+stale ones and print both reports.
#
# This script only REPORTS. It never edits, publishes, or redacts — every
# judgement call (is this hit a real leak?) is left to the reader, because the
# same regex fires on a genuine credential and on docker docs *about* passwords.
#
# DEPENDENCIES: grep (ERE), awk, sha256sum, git
#
# USAGE: audit.sh [--dotfiles DIR] [--site DIR] [--all]
#          --all   also scan pages that are already published (default: only
#                  the missing + stale ones, i.e. what a sync would push)

set -euo pipefail
#  -e exit on error · -u error on unset vars · -o pipefail fail a pipeline on any stage.

# ---- constants --------------------------------------------------------------
DOTFILES="${DOTFILES_DIR:-$HOME/Dotfiles}"
SITE="${SITE_DIR:-$HOME/Repos/benou-site}"
PAGES_SUBDIR="doc/pages"
CONTENT_SUBDIR="content/docs"
PSEUDO="benou"                 # the ONE identifier allowed to appear online
SCAN_ALL=0
SEP=$'\x1f'                    # unit separator: cannot occur inside a regex spec

# ---- helpers ----------------------------------------------------------------
log()  { printf '%s\n' "$*" >&2; }
die()  { log "audit: $1"; exit "${2:-1}"; }
need() { command -v "$1" &>/dev/null || die "missing dependency: $1"; }

# Read one key out of a file's FIRST front-matter block. Empty if absent.
# Anchored to NR==1 so a `---` rule inside the body can never be mistaken for it.
front_matter() {               # front_matter FILE KEY
    awk -v key="$2" '
        NR == 1 && $0 != "---" { exit }
        NR == 1                { next }
        $0 == "---"            { exit }
        index($0, key ":") == 1 {
            sub("^" key ":[ \t]*", "")
            gsub(/^"|"$/, "")
            print
            exit
        }
    ' "$1"
}

short_sha() { sha256sum -- "$1" | cut -c1-12; }

# ---- argument parsing -------------------------------------------------------
while (($#)); do
    case $1 in
        --dotfiles) DOTFILES=${2:?--dotfiles needs a path}; shift 2 ;;
        --site)     SITE=${2:?--site needs a path};         shift 2 ;;
        --all)      SCAN_ALL=1;                            shift   ;;
        -h|--help)  sed -n '2,20p' "$0"; exit 0 ;;
        *)          die "unknown argument: $1" ;;
    esac
done

for cmd in grep awk sha256sum git; do need "$cmd"; done
[[ -d $DOTFILES/$PAGES_SUBDIR ]]  || die "no $PAGES_SUBDIR under $DOTFILES"
[[ -d $SITE/$CONTENT_SUBDIR ]]    || die "no $CONTENT_SUBDIR under $SITE"

# ---- identity terms, derived from THIS machine ------------------------------
# Far more precise than guessing at names: we look for the real hostname, the
# real git identity and the real login — the things that actually identify the
# author — and never for the pseudonym, which is cleared for publication.
declare -a IDENTITY_TERMS=()
add_term() { [[ -n ${1:-} && ${1,,} != "$PSEUDO" ]] && IDENTITY_TERMS+=("$1") || true; }

add_term "$(hostname 2>/dev/null || true)"
add_term "${USER:-}"
add_term "$(git -C "$DOTFILES" config --get user.name  2>/dev/null || true)"
add_term "$(git -C "$DOTFILES" config --get user.email 2>/dev/null || true)"
add_term "$(git -C "$SITE"     config --get user.name  2>/dev/null || true)"
add_term "$(git -C "$SITE"     config --get user.email 2>/dev/null || true)"

# An email also leaks through its parts (first name, surname, provider-free local
# part), so split each address into searchable words of 4+ chars.
for t in "${IDENTITY_TERMS[@]:-}"; do
    [[ $t == *@* ]] || continue
    local_part=${t%@*}
    IFS='.+_-' read -ra words <<< "$local_part"
    for w in "${words[@]}"; do ((${#w} >= 4)) && add_term "$w"; done
done

# De-duplicate, case-insensitively.
mapfile -t IDENTITY_TERMS < <(printf '%s\n' "${IDENTITY_TERMS[@]:-}" | awk 'NF && !seen[tolower($0)]++')

# ---- pattern table ----------------------------------------------------------
# CATEGORY | human label | match regex | exclusion regex (a hit whose LINE matches
# this is dropped — it is how we keep textbook examples out of the report without
# blinding the net to the real thing).
#   BLOCK  — a credential shape. Treat every hit as real until proven otherwise.
#   REVIEW — machine/personal detail. Harmless in a generic example, never
#            harmless when it is *this* machine's actual value.
declare -a PATTERNS=(
    "BLOCK${SEP}private key block${SEP}-----BEGIN [A-Z ]*PRIVATE KEY-----${SEP}"
    "BLOCK${SEP}PGP private key${SEP}-----BEGIN PGP PRIVATE KEY BLOCK-----${SEP}"
    "BLOCK${SEP}SSH public key${SEP}ssh-(rsa|ed25519|dss) AAAA[0-9A-Za-z+/]{40,}${SEP}"
    "BLOCK${SEP}AWS access key id${SEP}(A3T|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[0-9A-Z]{16}${SEP}"
    "BLOCK${SEP}GitHub token${SEP}gh[pousr]_[A-Za-z0-9]{36}${SEP}"
    "BLOCK${SEP}GitHub fine-grained PAT${SEP}github_pat_[A-Za-z0-9_]{40,}${SEP}"
    "BLOCK${SEP}GitLab token${SEP}glpat-[A-Za-z0-9_-]{20,}${SEP}"
    "BLOCK${SEP}Slack token${SEP}xox[abprs]-[A-Za-z0-9-]{10,}${SEP}"
    "BLOCK${SEP}Google API key${SEP}AIza[0-9A-Za-z_-]{35}${SEP}"
    "BLOCK${SEP}JSON Web Token${SEP}eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.${SEP}"
    "BLOCK${SEP}WiFi pre-shared key${SEP}psk=[^[:space:]\"'\$]{6,}${SEP}"
    "BLOCK${SEP}high-entropy credential${SEP}(secret|token|passwd|password|api_?key|access_?key)[\"']?[[:space:]]*[:=][[:space:]]*[\"']?[A-Za-z0-9/+_-]{24,}${SEP}\\$\{|<[A-Z]|YOUR_|xxx|\.\.\."
    "REVIEW${SEP}credential-shaped assignment${SEP}(SECRET|TOKEN|PASSWORD|PASSWD|API_?KEY|PRIVATE_?KEY)[[:space:]]*=[[:space:]]*[^ \$\{<\"]${SEP}"
    "REVIEW${SEP}MAC address${SEP}\b([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}\b${SEP}(AA:BB:CC|00:00:00|XX:XX:XX|ff:ff:ff|FF:FF:FF)"
    "REVIEW${SEP}filesystem/disk UUID${SEP}\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b${SEP}(xxxxxxxx|XXXXXXXX|00000000|<uuid>)"
    "REVIEW${SEP}private IPv4 address${SEP}\b(192\.168\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3})\b${SEP}"
    "REVIEW${SEP}routable IPv4 address${SEP}\b([0-9]{1,3}\.){3}[0-9]{1,3}\b${SEP}\b(127\.|0\.0\.0\.0|255\.|192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.|169\.254\.|224\.|8\.8\.(8\.8|4\.4)|1\.1\.1\.1|1\.0\.0\.1|9\.9\.9\.9|192\.0\.2\.|198\.51\.100\.|203\.0\.113\.)|[0-9]\.[0-9]+\.[0-9]+\.[0-9]+-[0-9]|^\\|"
    "REVIEW${SEP}device serial number${SEP}[Ss]erial[[:space:]]*[:=][[:space:]]*[A-Za-z0-9-]{6,}${SEP}<|XXXX|example"
    "REVIEW${SEP}IMEI / ICCID / IMSI${SEP}\b(IMEI|ICCID|IMSI)\b[^A-Za-z]*[0-9]{6,}${SEP}"
    "REVIEW${SEP}email address${SEP}[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}${SEP}(@(openssh|libssh|openwall|example|gnu)\.(com|org|net)|Ciphers |KexAlgorithms |MACs |HostKeyAlgorithms |PubkeyAcceptedAlgorithms )"
    "REVIEW${SEP}phone number${SEP}\+[0-9]{2,3}[ .-]?[0-9]{2,3}[ .-]?[0-9]{3}[ .-]?[0-9]{2,4}${SEP}"
    "REVIEW${SEP}postal address / coordinates${SEP}\b[0-9]{4,5}[[:space:]]+(Lausanne|Geneva|Gen\xc3\xa8ve|Zurich|Z\xc3\xbcrich|Bern|Basel)\b${SEP}"
)

# ---- inventory: what the site already publishes -----------------------------
declare -A PUB_SHA PUB_PATH
while IFS= read -r -d '' page; do
    src=$(front_matter "$page" source)
    [[ -n $src ]] || continue
    PUB_SHA[$src]=$(front_matter "$page" source_sha)
    PUB_PATH[$src]=${page#"$SITE"/}
done < <(find "$SITE/$CONTENT_SUBDIR" -name '*.md' -print0)

# ---- inventory: what the dotfiles hold --------------------------------------
declare -a MISSING=() STALE=() SYNCED=()
declare -A SEEN_SRC=()

while IFS= read -r -d '' src_file; do
    rel=${src_file#"$DOTFILES"/}                 # doc/pages/<section>/<slug>.md
    base=$(basename "$rel")
    [[ $base == _* || $base == README.md ]] && continue
    SEEN_SRC[$rel]=1
    sha=$(short_sha "$src_file")
    if [[ -z ${PUB_SHA[$rel]:-} ]]; then
        MISSING+=("$rel${SEP}$sha")
    elif [[ ${PUB_SHA[$rel]} != "$sha" ]]; then
        STALE+=("$rel${SEP}$sha${SEP}${PUB_SHA[$rel]}${SEP}${PUB_PATH[$rel]}")
    else
        SYNCED+=("$rel${SEP}${PUB_PATH[$rel]}")
    fi
done < <(find "$DOTFILES/$PAGES_SUBDIR" -name '*.md' -print0 | sort -z)

# Published pages whose source has disappeared, and hand-written pages.
declare -a ORPHANED=() UNTRACKED=()
for src in "${!PUB_PATH[@]}"; do
    [[ -n ${SEEN_SRC[$src]:-} ]] || ORPHANED+=("$src${SEP}${PUB_PATH[$src]}")
done
while IFS= read -r -d '' page; do
    base=$(basename "$page")
    [[ $base == _index.md ]] && continue
    [[ -z $(front_matter "$page" source) ]] && UNTRACKED+=("${page#"$SITE"/}")
done < <(find "$SITE/$CONTENT_SUBDIR" -name '*.md' -print0 | sort -z)

# ---- report: inventory ------------------------------------------------------
printf '=== INVENTORY ===\n'
printf 'dotfiles : %s/%s\n' "$DOTFILES" "$PAGES_SUBDIR"
printf 'site     : %s/%s\n\n' "$SITE" "$CONTENT_SUBDIR"

for e in "${MISSING[@]:-}"; do
    [[ -n $e ]] && printf 'MISSING    %-52s sha %s\n' "${e%%"$SEP"*}" "${e##*"$SEP"}"
done
for e in "${STALE[@]:-}"; do
    [[ -n $e ]] || continue
    IFS="$SEP" read -r rel now was path <<< "$e"
    printf 'STALE      %-52s published %s → now %s (%s)\n' "$rel" "$was" "$now" "$path"
done
for e in "${SYNCED[@]:-}"; do
    [[ -n $e ]] && printf 'SYNCED     %-52s %s\n' "${e%%"$SEP"*}" "${e##*"$SEP"}"
done
for e in "${ORPHANED[@]:-}"; do
    [[ -n $e ]] && printf 'ORPHANED   %-52s %s (source gone)\n' "${e%%"$SEP"*}" "${e##*"$SEP"}"
done
for e in "${UNTRACKED[@]:-}"; do
    [[ -n $e ]] && printf 'UNTRACKED  %s (hand-written, no source:)\n' "$e"
done

printf '\nmissing %d · stale %d · synced %d · orphaned %d · untracked %d\n' \
    "${#MISSING[@]}" "${#STALE[@]}" "${#SYNCED[@]}" "${#ORPHANED[@]}" "${#UNTRACKED[@]}"

# ---- report: scan -----------------------------------------------------------
# Only the pages a sync would actually push, unless --all.
declare -a TO_SCAN=()
for e in "${MISSING[@]:-}"; do [[ -n $e ]] && TO_SCAN+=("${e%%"$SEP"*}"); done
for e in "${STALE[@]:-}";   do [[ -n $e ]] && TO_SCAN+=("${e%%"$SEP"*}"); done
if ((SCAN_ALL)); then
    for e in "${SYNCED[@]:-}"; do [[ -n $e ]] && TO_SCAN+=("${e%%"$SEP"*}"); done
fi

printf '\n=== SCAN (%d pages) ===\n' "${#TO_SCAN[@]}"
printf 'allowed identifier: %s\n' "$PSEUDO"
printf 'identity terms    : %s\n\n' "${IDENTITY_TERMS[*]:-none}"

hits=0
emit() {                       # emit CATEGORY LABEL FILE LINENO TEXT
    printf '%-6s  %-28s  %s:%s\n            %s\n' \
        "$1" "$2" "$3" "$4" "$(printf '%s' "$5" | cut -c1-140)"
    hits=$((hits + 1))
}

for rel in "${TO_SCAN[@]:-}"; do
    [[ -n $rel ]] || continue
    f="$DOTFILES/$rel"

    # Identity terms first: these are this machine's real values, so a hit is
    # never a coincidence and never a generic example.
    for term in "${IDENTITY_TERMS[@]:-}"; do
        [[ -n $term ]] || continue
        while IFS=: read -r n text; do
            [[ -n $n ]] && emit "IDENT" "real identifier: $term" "$rel" "$n" "$text"
        done < <(grep -niF -- "$term" "$f" || true)
    done

    # A home directory belonging to someone other than the pseudonym is a real
    # username leak; /home/benou is the one that is cleared for publication.
    while IFS=: read -r n text; do
        [[ -n $n ]] || continue
        printf '%s' "$text" | grep -qE "/home/$PSEUDO(/|\\b)" && continue
        emit "IDENT" "foreign home directory" "$rel" "$n" "$text"
    done < <(grep -nE '/home/[a-z][a-z0-9_-]*' "$f" | grep -vE "/home/$PSEUDO(/|[^a-z0-9_-])" || true)

    for spec in "${PATTERNS[@]}"; do
        cat=${spec%%"$SEP"*};   rest=${spec#*"$SEP"}
        label=${rest%%"$SEP"*}; rest=${rest#*"$SEP"}
        re=${rest%%"$SEP"*};    excl=${rest#*"$SEP"}
        while IFS=: read -r n text; do
            [[ -n $n ]] || continue
            # Drop textbook examples, placeholders and lookalikes.
            if [[ -n $excl ]] && printf '%s' "$text" | grep -qE -- "$excl"; then
                continue
            fi
            emit "$cat" "$label" "$rel" "$n" "$text"
        done < <(grep -nE -- "$re" "$f" 2>/dev/null || true)
    done
done

printf '\n%d hit(s) across %d page(s).\n' "$hits" "${#TO_SCAN[@]}"
printf 'Hits are QUESTIONS, not verdicts — a page documenting POSTGRES_PASSWORD=dev\n'
printf 'is clean; the same regex on a real value is not. Review each one.\n'
