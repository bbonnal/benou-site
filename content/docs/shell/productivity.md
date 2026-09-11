---
title: "Shell productivity"
date: 2026-05-23
tags: ["shell", "zsh", "shortcuts"]
source: doc/pages/shell/productivity.md
source_sha: 761cb750b1c3
---

> Bash/zsh keyboard shortcuts, history, aliases, functions, globbing, parameter expansion, brace expansion, misc tricks.

## Modes (zsh-vi-mode)

- `Esc` / `Ctrl+[` — insert → normal
- `i` / `a` — insert before / after cursor
- `I` / `A` — insert at start / end of line
- `o` — newline (multi-line edit)
- `v` — open current command in `$EDITOR`
- Cursor changes shape per mode (block in normal, beam in insert).

## Movement (normal mode)

| Key | Action |
|-----|--------|
| `h` / `l` | char left / right |
| `j` / `k` | next / previous history entry |
| `w` / `W` | next word / WORD |
| `b` / `B` | back word / WORD |
| `e` / `E` | end of word / WORD |
| `0` | beginning of line |
| `^` | first non-blank |
| `$` | end of line |
| `f<c>` / `F<c>` | find char forward / back |
| `t<c>` / `T<c>` | till char forward / back |
| `;` / `,` | repeat find forward / reverse |
| `gg` / `G` | oldest / newest history entry |
| `%` | matching bracket |

## Editing (normal mode)

Operator + motion: `d`, `c`, `y` combine with any movement (`dw`, `c$`, `yiw`, …).

| Key | Action |
|-----|--------|
| `x` / `X` | delete char under / before cursor |
| `dd` | delete whole line |
| `D` / `C` | delete / change to end of line |
| `cc` | change whole line |
| `s` / `S` | substitute char / line |
| `r<c>` / `R` | replace char / replace mode |
| `~` | toggle case |
| `p` / `P` | paste after / before |
| `yy` | yank line |
| `u` / `Ctrl+R` | undo / redo |
| `.` | repeat last change |

### Text objects (with `d` / `c` / `y`)

`iw aw i" a" i' a' i( a( i{ a{ i[ a[ i<motion>` — e.g. `ci"` change inside quotes, `daw` delete around word.

### Surround (zsh-vi-mode)

- `S<char>` — wrap visual selection
- `ys<motion><char>` — add surround (e.g. `ysiw"`)
- `cs<old><new>` — change surround (e.g. `cs"'`)
- `ds<char>` — delete surround

## Control (any mode)

| Shortcut | Action |
|----------|--------|
| `Ctrl+R` | fzf history search (rebound in `.zshrc`) |
| `Ctrl+W` | delete word before |
| `Ctrl+U` | delete to beginning of line |
| `Ctrl+L` | clear screen |
| `Ctrl+C` | cancel current line |
| `Ctrl+Z` | suspend foreground job |
| `Ctrl+D` | exit shell (empty line) |
| `Ctrl+J/K` | down / up in fzf widgets |

## History

- Show:
  `history` / `history 20`

- Search:
  `history | grep docker`

- Interactive reverse:
  `Ctrl+R`

### Expansion

- Repeat last:
  `!!`

- Run #42:
  `!42`

- Last starting with docker:
  `!docker`

- Last containing keyword:
  `!?keyword`

### Reuse arguments

- Last arg:
  `!$`

- First arg:
  `!^`

- All args:
  `!*`

- By position (0 = command):
  `!:2`

- Range:
  `!:2-4`

### Substitute & rerun

- Replace first in last:
  `^old^new`

- Replace all in last:
  `!!:gs/old/new`

### History config

```
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth
export HISTIGNORE="ls:cd:exit"
export HISTTIMEFORMAT="%F %T "
shopt -s histappend
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
```

## Aliases

```
alias ll='ls -lah'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias mkdir='mkdir -pv'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
```

- Show all:
  `alias`

- Remove (session):
  `unalias ll`

- Bypass alias:
  `\rm file.txt` / `command rm file.txt`

## Functions

```bash
mkcd() { mkdir -p "$1" && cd "$1"; }

extract() {
    case "$1" in
        *.tar.gz|*.tgz)  tar xzf "$1" ;;
        *.tar.bz2|*.tbz) tar xjf "$1" ;;
        *.tar.xz|*.txz)  tar xJf "$1" ;;
        *.tar.zst)       tar --zstd -xf "$1" ;;
        *.tar)           tar xf "$1" ;;
        *.gz)            gunzip "$1" ;;
        *.bz2)           bunzip2 "$1" ;;
        *.xz)            unxz "$1" ;;
        *.zip)           unzip "$1" ;;
        *.7z)            7z x "$1" ;;
        *)               echo "Unknown: $1" ;;
    esac
}

fcd() { cd "$(fd -t d "$1" | head -1)"; }

bak() { cp "$1" "$1.bak.$(date +%F_%H%M%S)"; }
```

## Globbing

- Basic wildcards:
  ```
  ls *.txt              # any .txt
  ls file?.txt          # ? = one char
  ls file[123].txt      # any of 1,2,3
  ls file[a-z].txt      # range
  ls file[!0-9].txt     # NOT digit
  ```

- Recursive (`**`) — bash needs `shopt -s globstar`:
  `ls **/*.py`

- Extended (`shopt -s extglob`):
  ```
  ls !(*.log)           # except .log
  ls +(*.jpg|*.png)     # one or more
  ls ?(a|b).txt         # optional
  ls @(*.jpg|*.png)     # exactly one
  ls *(pattern)         # zero or more
  ```

### Zsh-specific

```
ls **/*.py
ls *.txt(.)           # regular files only
ls *(/)               # dirs only
ls *(@)               # symlinks only
ls *(m-7)             # modified < 7 days
ls *(Lk+100)          # > 100 KB
ls *(om[1,5])         # 5 most recent
```

- Null-glob (expand to nothing on no match):
  bash: `shopt -s nullglob` — zsh: `setopt nullglob`

## Parameter expansion

```
${var:-default}          # use default if unset/empty
${var:=default}          # set default if unset/empty
${#var}                  # length
${var:0:4}               # substring (offset,length)
${var:5}                 # substring from offset
${var: -2}               # last 2 (note space)
```

### Prefix/suffix removal

`#`/`%` shortest, `##`/`%%` longest.

```
name="file.tar.gz"
path="/home/jo/documents/file.txt"

${name#*.}    → tar.gz
${name##*.}   → gz
${name%.*}    → file.tar
${name%%.*}   → file

${path##*/}   → file.txt   (like basename)
${path%/*}    → /home/jo/documents   (like dirname)
```

### Replace

```
${name/tar/zip}          # first
${name//./,}             # all
${name/#file/doc}        # prefix
${name/%.gz/.xz}         # suffix
```

### Case (bash 4+)

```
${name^^}                # all upper
${name,,}                # all lower
${name^}                 # capitalize first
```

### Indirect / arrays

```
ref="name"; echo ${!ref}     # indirect

arr=(one two three)
echo ${arr[@]}               # all
echo ${#arr[@]}              # length
echo ${arr[@]:1:2}           # slice
```

## Brace expansion

- Sequences:
  ```
  {1..10}            → 1 2 ... 10
  {a..z}
  {01..12}           # zero-padded
  {1..20..2}         # step
  ```

- Combinations (cartesian product):
  `{a,b}{1,2}` → a1 a2 b1 b2

- Practical:
  ```
  mkdir -p project/{src,test,docs}/{main,utils}
  cp file.txt{,.bak}            # quick backup
  mv file.{old,new}             # rename
  touch file{1..10}.txt
  ```

## Job control

- Background:
  `sleep 100 &`

- Jobs:
  `jobs` / `jobs -l`

- Foreground / background:
  `fg %1` / `bg %1`

- Suspend foreground:
  `Ctrl+Z`

- Detach from shell:
  `disown %1` / `disown -a`

- Wait:
  `wait` / `wait %1` / `wait $PID`

## Misc tricks

- Sudo previous:
  `sudo !!`

- Last two dirs toggle:
  `cd -`

- Directory stack:
  ```
  pushd /new/dir
  popd
  dirs -v
  ```

- Process substitution:
  ```
  diff <(sort f1) <(sort f2)
  while read -r line; do echo "$line"; done < <(some-cmd)
  ```

- Redirection:
  ```
  cmd 2>/dev/null         # silence errors
  cmd 2>&1                # err → out
  cmd &> output.txt       # both to file
  cmd 2>&1 | tee log.txt  # both file + screen
  ```

- Here string / heredoc:
  ```
  grep "pattern" <<< "string to search"

  cat << 'EOF' > script.sh
  #!/bin/bash
  echo "hello"
  EOF
  ```

- Command substitution:
  `echo "Today is $(date +%F)"`

- Arithmetic:
  ```
  echo $((2 + 3))
  echo $((10 ** 2))
  ((count++))
  ```

- Time a command:
  `time tar czf archive.tar.gz dir/`

- Auto-yes / auto-no:
  `yes | cmd` / `yes n | cmd`
