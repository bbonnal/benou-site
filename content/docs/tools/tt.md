---
title: "tt typing practice"
date: 2026-05-23
tags: ["tools", "typing", "tt"]
source: doc/pages/tools/tt.md
source_sha: 41c3abf7626b
---

> Typing-practice corpora and launcher for [tt](https://github.com/lemnos/tt).
> Stow-linked from this repo to `~/.config/tt/practice/` and `~/.local/bin/tt-practice`.

## Launch

- Interactive menu (category → corpus → mode):
  `tt-practice`

Menu flow:
1. Category — `Code`, `Literary`, `Scramble`, or `Random Mix`
2. Corpus (skipped for Random Mix, which picks one JSON at random)
3. Mode — `30s`, `60s`, `120s`, or `-oneshot` (quote-based)

Override the source dir: `PRACTICE_DIR=... tt-practice`

## Corpora (`~/.config/tt/practice/`)

### Code (symbol-heavy)

- `python.json` — comprehensions, decorators, f-strings, type hints, asyncio, dataclasses
- `csharp.json` — LINQ, async/await, generics, records, pattern matching
- `terminal.json` — find/grep/rg/sed/awk/xargs, git, ssh, systemd, curl

### Literary (prose rhythm)

- `petit-prince-fr.json`, `petit-prince-en.json` — **original paraphrases** of Le Petit Prince by chapter (not the copyrighted text — see licensing below)

### Scramble (Monkeytype-style, 30–50 random words/entry)

- `scramble-fr-1k.json`, `scramble-en-1k.json` — top 1000 words (muscle memory)
- `scramble-fr-full.json`, `scramble-en-full.json` — full ~50k frequency list (vocabulary breadth)

## Regenerate scrambles

- All files:
  `python3 ~/.config/tt/practice/generators/generate_scrambles.py`

- Single file:
  `python3 ~/.config/tt/practice/generators/generate_scrambles.py --only en-full`

Sources tried in order: FrequencyWords (network) → dwyl/english-words (en-full only) → `/usr/share/dict/`. Deterministic for a fixed `--seed`.

## Adding a new corpus

1. Drop a flat-array JSON into `.config/tt/practice/`
2. Add it to `.local/bin/tt-practice` (`declare -A` map + matching `*_ORDER` array)
3. Re-run `stow -v .` only if you added a new directory

## Format gotcha

`tt -quotes <file>` wants a **flat JSON array**, not an object:

```json
[ {"text": "...", "attribution": "..."} ]
```

Wrapping in `{"language": ..., "quotes": [...]}` errors with
`cannot unmarshal object into Go value of type []main.segment`.

## Petit Prince licensing

French original is in copyright in FR until **2032** (standard term + war
extensions + *mort pour la France*). Translations have their own clocks.
The shipped files are original paraphrases to stay clearly safe — see
`generators/README.md` for jurisdiction-by-jurisdiction reasoning.
