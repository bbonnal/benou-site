---
title: "Typst"
date: 2026-03-11
tags: ["tools", "typst", "documents"]
source: doc/pages/tools/typst.md
source_sha: 42731fe5e159
---

> Typst document compilation and live preview workflow.

## Basic commands

- Compile to PDF:
  `typst c report.typ`

- Compile with a custom root (for imports from parent dirs):
  `typst c report.typ --root .`

- Watch and recompile on save:
  `typst watch report.typ`

- Open PDF viewer alongside (zathura auto-reloads):
  `typst watch report.typ & zathura report.pdf`

## Typical workflow

```
typst watch report.typ   # terminal 1: auto-compile
zathura report.pdf       # terminal 2: auto-reloading viewer
nvim report.typ          # editor
```

## Package management

- Local packages live in:
  `~/.local/share/typst/packages/local/<name>/<version>/`

- Install local package (copy or symlink):
  `ln -s ~/Repos/benou-typst/packages/local/benou ~/path/to/typst/packages/local/`

## Tips

- `zathura` auto-reloads the PDF when it changes — no need to reopen
- Use `typst watch` instead of re-running `typst c` manually
- `--root .` is needed when importing from `../../` paths
