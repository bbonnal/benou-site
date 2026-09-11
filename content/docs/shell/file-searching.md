---
title: "File searching"
date: 2026-05-23
tags: ["shell", "find", "ripgrep"]
source: doc/pages/shell/file-searching.md
source_sha: 3bce13643fc5
---

> find, fd, locate, grep, ripgrep.

## find

### Name + type

- By name:
  `find /etc -name "*.conf"`

- Case-insensitive:
  `find /home -iname "*.jpg"`

- Directories only:
  `find /var -type d -name "log*"`

- Files only:
  `find . -type f -name "*.txt"`

### Size

`+` = greater than, `-` = less than. Suffix: c (bytes), k, M, G.

- > 100 MB:
  `find / -type f -size +100M`

### Time

`-mtime` (days), `-mmin` (minutes). `-` = less than N ago, `+` = more than. Also `-atime`, `-ctime`.

- Modified < 7 days:
  `find /home -type f -mtime -7`

- Modified > 30 days:
  `find /var/log -type f -mtime +30`

- Changed in last hour:
  `find . -type f -mmin -60`

### Other filters

- Empty:
  `find /tmp -empty`

- Exact perms:
  `find / -type f -perm 777`

- SUID:
  `find / -type f -perm /u+s`

- By owner / group:
  `find /home -type f -user jo`
  `find /var -type f -group wheel`

### Combine

- AND (default):
  `find . -type f -name "*.log" -size +10M`

- OR:
  `find . -type f \( -name "*.jpg" -o -name "*.png" \)`

- Negate:
  `find . -type f ! -name "*.tmp"`

### Depth

- Max 2 levels:
  `find . -maxdepth 2 -name "*.conf"`

- Direct child dirs in /etc:
  `find /etc -mindepth 1 -maxdepth 1 -type d`

### Exec

- Per-file:
  `find . -type f -name "*.log" -exec rm {} \;`

- With confirmation:
  `find . -type f -name "*.bak" -ok rm {} \;`

- Batched (more efficient):
  `find . -type f -name "*.txt" -exec grep -l "TODO" {} +`

- Built-in delete (fastest):
  `find /tmp -type f -name "*.tmp" -mtime +7 -delete`

### Tricks

- Sort by mtime:
  `find . -type f -printf "%T@ %p\n" | sort -n`

- Broken symlinks:
  `find . -xtype l`

- Exclude a dir:
  `find . -path ./node_modules -prune -o -type f -name "*.js" -print`

- Exclude multiple:
  `find . \( -path ./.git -o -path ./vendor \) -prune -o -type f -print`

## fd

Install `fd`. Recursive + smart-case + respects `.gitignore` + colorized by default.

- Regex name search:
  `fd "\.conf$" /etc`

- By extension:
  `fd -e jpg`
  `fd -e txt -e md`

- Include hidden / ignored:
  `fd -H ".bashrc"`
  `fd -I "node_modules"`
  `fd -HI "*.log"`

- Type (`f`/`d`/`l`/`x`/`e`):
  `fd -t d "src"`
  `fd -t f "config"`
  `fd -t x`               # executable
  `fd -t e`               # empty

- Max depth:
  `fd -d 2 "*.md"`

- Exclude dirs:
  `fd -E node_modules -E .git "\.js$"`

- Absolute paths:
  `fd -a "\.conf$" /etc`

- Base directory:
  `fd -e rs --base-directory /usr/src`

### Exec (`-x` per result, `-X` batch)

Placeholders: `{}` full, `{.}` no ext, `{/}` basename, `{//}` parent, `{/.}` basename no ext.

- Per result:
  `fd -e log -x gzip {}`

- Parallel convert:
  `fd -e png -x convert {} {.}.webp`

- Batched:
  `fd -e txt -X wc -l`

- Move with placeholders:
  `fd -e jpg -x mv {} {//}/thumbnails/{/}`

### Filter size / time

- Size:
  `fd -S +1m -e log`

- Modified time:
  `fd --changed-within 1d`
  `fd --changed-before "2025-01-01"`

## locate / plocate

Install `plocate`.

- Update DB (run as root or via timer):
  `sudo updatedb`

- Search:
  `locate bashrc`

- Case-insensitive:
  `locate -i readme`

- Count matches:
  `locate -c "*.conf"`

- Limit results:
  `locate -l 10 "*.log"`

- Only existing files:
  `locate -e "*.conf"`

- Regex:
  `locate -r "/etc/.*\.conf$"`

- Regex + insensitive:
  `locate -ri "readme\.md$"`

- DB stats:
  `locate -S`

## grep

- Basic:
  `grep "error" /var/log/syslog`

- Recursive:
  `grep -r "TODO" ./src`

- Recursive, skip binary:
  `grep -rI "password" /etc`

- Case-insensitive:
  `grep -ri "error" /var/log/`

### Output control

- Line numbers:
  `grep -rn "function" ./src`

- Filenames only:
  `grep -rl "import React" ./src`

- Count per file:
  `grep -rc "TODO" ./src`

- Context:
  ```
  grep -B 3 "panic" log    # 3 before
  grep -A 5 "error" log    # 5 after
  grep -C 2 "fatal" log    # 2 both
  ```

### Regex flavors

- Extended (`-E`):
  `grep -E "(error|warning|fatal)" log`

- Perl (`-P`):
  `grep -P "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" access.log`

### Match modes

- Invert:
  `grep -v "^#" /etc/fstab`

- Whole word:
  `grep -w "error" log`

- Exact line:
  `grep -x "exact line" file`

- Fixed string (no regex):
  `grep -F "user.name[0]" config`

### Multiple patterns

- `-e` repeated:
  `grep -e "error" -e "warning" log`

- From file:
  `grep -f patterns.txt log`

### Include / exclude

- Include:
  `grep -r --include="*.py" "import" ./src`

- Exclude:
  `grep -r --exclude="*.min.js" "function" ./src`

- Exclude dir:
  `grep -r --exclude-dir=".git" "TODO" .`

### Other

- Null output for xargs:
  `grep -rZl "TODO" ./src | xargs -0 rm`

- Only matched portion:
  `grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" access.log`

- Quiet (exit code):
  `if grep -q "error" log; then echo "found"; fi`

## ripgrep (rg)

Install `ripgrep`. Faster, sensible defaults, respects `.gitignore`.

- Basic:
  `rg "TODO"`

- In directory:
  `rg "error" /var/log`

- Fixed string:
  `rg -F "user.name[0]"`

### File types

- One type:
  `rg -t py "import"`

- Multiple:
  `rg -t js -t ts "fetch"`

- List available types:
  `rg --type-list`

- Custom type:
  `rg --type-add "web:*.{html,css,js}" -t web "color"`

### Case

- Insensitive:
  `rg -i "error"`

- Smart case (sensitive if uppercase used):
  `rg -S "Error"`

### Output

- Context:
  `rg -C 3 "panic"`
  `rg -B 2 -A 5 "error"`

- Files only:
  `rg -l "TODO"`

- Files without match:
  `rg --files-without-match "TODO"`

- Counts per file:
  `rg -c "error" /var/log`

### Hidden / ignored

- Hidden:
  `rg --hidden "secret"`

- Ignore `.gitignore`:
  `rg --no-ignore "debug"`

- Everything (hidden + ignored):
  `rg -uu "password"`

### Globs

- Include:
  `rg -g "*.py" "import"`

- Exclude:
  `rg -g "!*.min.js" "function"`

- Path glob:
  `rg -g "src/**/*.ts" "interface"`

### Advanced

- Multiline:
  `rg -U "fn main.*\{[\s\S]*?\}"`

- Replace preview:
  `rg "foo" -r "bar"`

- Only matched portion:
  `rg -o "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"`

- JSON output:
  `rg --json "TODO"`

- Sort by path:
  `rg --sort path "error"`

- Max depth:
  `rg --max-depth 2 "config"`

- Max matches per file:
  `rg -m 5 "error"`

- In compressed files:
  `rg -z "error" logs.gz`

- Null separator for xargs:
  `rg -0 -l "TODO" | xargs -0 sed -i 's/TODO/DONE/g'`

- Stats:
  `rg --stats "TODO"`

- PCRE2 (lookahead/lookbehind):
  `rg -P "(?<=user=)\w+" access.log`

## Combine

- Find then grep:
  `find . -name "*.conf" -exec grep -l "Listen" {} +`

- fd + rg:
  `fd -e py | xargs rg "import os"`

- Recently modified only:
  `fd -e log --changed-within 1h -x rg "error" {}`

- locate + grep:
  `locate -r "\.conf$" | xargs grep -l "port"`

- Large log files w/ errors:
  `find /var/log -name "*.log" -size +10M -exec grep -l "ERROR" {} +`

- Duplicate filenames:
  `fd -t f | awk -F/ '{print $NF}' | sort | uniq -d`

- Open matches in editor:
  `rg -l "TODO" | xargs $EDITOR`

- LOC by extension:
  `fd -e py | xargs wc -l | sort -n`

- Interactive search (fzf):
  `fd -t f | fzf --preview 'bat {}'`
  `rg --files | fzf --preview 'head -50 {}'`
