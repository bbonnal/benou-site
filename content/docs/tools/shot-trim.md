---
title: "shot-trim"
date: 2026-09-11
tags: ["tools", "screenshots", "imagemagick"]
source: doc/pages/tools/shot-trim.md
source_sha: 0ebf36c7d935
---

> Batch-crop screenshots by a fixed pixel inset per side — the same amount on three
> sides, a larger one on top — writing the results to a `trimmed/` subdirectory.

`grimshot save window` (bound to `Ctrl+Print`, see [sway/keybindings](/docs/sway/keybindings/))
captures the *whole* window node, chrome included. For a QEMU VM window that means two
bands you never want in a document: sway's frame all the way round, and the VM's own GTK
menubar along the top. `shot-trim` removes both in one pass over a batch and never touches
the originals.

## Run it

```
shot-trim ~/Screenshots/2026-08-23T12*.png
```

Each file is cropped and written to `<its dir>/trimmed/<same name>`; one line per file,
then a summary:

```
$ cd ~/Screenshots && shot-trim 2026-08-23T12*.png
2026-08-23T12:05:12,251788794+02:00.png  1222x880 -> 1212x843
2026-08-23T12:25:46,613768577+02:00.png  1201x979 -> 1191x942
22 trimmed, 0 skipped, 0 failed
```

Check before committing to it with `-n` (dry run: prints the same lines plus the
destination path, writes nothing).

## Why the defaults are 5 and 32

| Band | Size | What it is |
|-----------------|-------|--------------------------------------------------------------|
| all four sides  | 5 px  | sway's frame — `default_border pixel 5` in `.config/sway/config`. `grimshot save window` captures the node `rect`, which includes it (`window_rect` sits at `+5+5`). |
| top, inside that| 27 px | the QEMU GTK menubar (`Machine` / `View`), `srgb(53,53,53)`. |

So: 5 px left/right/bottom, and 5 + 27 = **32 px** top. **If `default_border` changes, the
side defaults in the script have to change with it** — nothing detects the frame at run
time, by design (a fixed inset gives every shot in a batch the same size, which matters
when they get stacked in a document).

## Options

```
shot-trim [-l N] [-r N] [-b N] [-t N] [-o DIR] [-n] FILE...

  -l N    left inset, px          (default 5)
  -r N    right inset, px         (default 5)
  -b N    bottom inset, px        (default 5)
  -t N    top inset, px           (default 32)
  -o DIR  output directory        (default: <dir of each input>/trimmed)
  -n      dry run
  -h      help
```

Exit status: `0` everything trimmed · `1` usage or dependency error · `2` some files were
skipped or failed.

- A capture without the VM menubar (an `area` grab, say): `shot-trim -t 5 shot.png`.
- Collect a mixed batch in one place: `shot-trim -o ~/doc-figures *.png`.

## Without the script

The operation itself is one ImageMagick call, if you'd rather not install anything:

```bash
mkdir -p trimmed && mogrify -path trimmed -shave 5x5 -gravity North -chop 0x27 +repage *.png
```

`-shave 5x5` takes 5 px off all four sides, `-chop 0x27` takes the menubar off the top.
The script exists for the guards below, not for the crop.

## Robustness invariants

- **Temp file, then `mv`.** Every output is written to `.shot-trim.XXXXXX` *in the
  destination directory* and moved into place, so a failed or interrupted `magick` can
  never leave a truncated PNG at the real path. The EXIT trap sweeps the temp files;
  verified with a stubbed `magick` that fails, and with a Ctrl-C mid-crop (exit 130, no
  leftovers).
- **`+repage` is not optional.** Without it the crop offset is recorded in the PNG and
  downstream tools inherit a `+5+32` page geometry.
- **`png:` on the writer.** The output format comes from the coder prefix, never from the
  temp file's name.
- **Inputs are never outputs.** A file already sitting in a `trimmed/` directory is
  skipped (it has been cropped once already; pass `-o` to crop it again on purpose), and
  so is any file whose directory *is* the `-o` destination — that case would overwrite the
  original.
- **grimshot filenames contain colons** (`2026-08-23T12:25:46,…`). ImageMagick reads a
  `prefix:` as a coder name, but falls back to treating the whole string as a path when no
  coder matches — `2026-08-23T12` never will. Verified across the folder.
- Insets that would leave nothing (`-t 500` on a 468 px-tall shot) are reported as a skip,
  not passed to ImageMagick.

## Known limitations

- **PNG only.** Non-`.png` inputs are skipped, since the writer forces `png:`.
- **Fixed insets, no detection.** Deliberate — see above.
- No single-instance lock and no `notify-send`: this is a terminal tool, not a keybinding
  (see the deviations noted in the script header and
  [dev/authoring-shell-utilities](/docs/dev/authoring-shell-utilities/) §0, §7.2).
