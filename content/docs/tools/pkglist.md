---
title: "pkglist"
date: 2026-06-15
tags: ["tools", "pacman", "inventory"]
source: doc/pages/tools/pkglist.md
source_sha: b16f45f10f80
---

> Regenerate the committed inventory of every installed package.

`pkglist` queries pacman and writes three files in one run: the human-readable page
`system/installed-packages` (explicitly-installed
packages with descriptions, AUR/foreign packages, orphans, and the full list for
grepping), plus two plain-text reinstall lists next to it. Run it whenever you want them
refreshed — it answers "what was that package for?" *and* hands you the lists to rebuild
a machine from scratch.

## Run it

```
pkglist
```

That's the whole thing. `pkglist` lives in `~/.local/bin` (on `$PATH`), so just type it
from anywhere. It prints a one-line summary and writes the page into the repo:

```
$ pkglist
wrote 1499 total, 198 explicit, 19 AUR
  doc         → ~/Dotfiles/doc/pages/system/installed-packages.md
  native list → ~/Dotfiles/doc/pages/system/installed-packages.txt (189 pkgs)
  AUR list    → ~/Dotfiles/doc/pages/system/installed-packages.aur.txt (9 pkgs)
```

Then commit the refreshed files:

```
cd ~/Dotfiles && git add 'doc/pages/system/installed-packages*' && git commit -m "Refresh package inventory"
```

## Options

- Write somewhere else (e.g. to inspect without touching the repo):
  `pkglist -o /tmp/pkgs.md`
- Help:
  `pkglist -h`

## Where it writes

All under `~/Dotfiles/doc/pages/system/`, sharing one basename:

- `installed-packages.md` — the human-readable inventory.
- `installed-packages.txt` — explicit **native** package names, one per line.
- `installed-packages.aur.txt` — explicit **AUR/foreign** package names.

The path is resolved from the script's own location (it sits at `.local/bin/pkglist` in
the repo, stowed to `~/.local/bin`), so it always writes back into the repo no matter
where you run it. `doc/` is stow-ignored, so these live only in the repo — read the page
with `bdoc` (fuzzy-grep) like any other, or open the files directly. Pass `-o FILE.md`
to write the whole set elsewhere (the `.txt` names are derived from it).

## Reinstall on another machine

The `.txt` files are pure package-name lists, so they pipe straight into a package
manager on a fresh Arch box (after cloning the dotfiles):

```
# native packages from the official repos
sudo pacman -S --needed - < ~/Dotfiles/doc/pages/system/installed-packages.txt

# AUR packages (after bootstrapping an AUR helper such as yay)
yay -S --needed - < ~/Dotfiles/doc/pages/system/installed-packages.aur.txt
```

`--needed` skips anything already present, so it's safe to re-run. Only *explicitly*
installed packages are listed — the package manager pulls in their dependencies.

## How it works

- Counts come from `pacman -Q` / `-Qe` / `-Qn` / `-Qm` / `-Qdt`.
- The description tables are parsed from `pacman -Qi` output (run under `LC_ALL=C` so
  the field labels stay English) — no extra tools needed.
- Tables are column-aligned (padded with spaces) so the borders line up when read as
  raw text in nvim; the padding is whitespace that markdown renderers trim, so it still
  renders as a normal table.
- The page is built in a temp file and moved into place atomically, so an interrupted
  run never leaves a half-written page.

## Dependencies

`pacman` and `awk` — both always present on Arch. `expac` is **not** required.

## Refresh policy

Manual on purpose: you run `pkglist` when you want a fresh snapshot, then commit it, so
the git history doubles as a timeline of what changed on the system. There is no timer
or pacman hook — nothing runs behind your back.
