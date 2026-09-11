# Converting a dotfiles page into a Hugo page

## Shapes

A dotfiles page (`~/Dotfiles/doc/pages/<section>/<slug>.md`) looks like this:

```markdown
# tmux

> Tmux keybindings. Prefix is Ctrl+S.

Ghostty starts tmux for every window...

## Custom bindings
```

The Hugo page (`content/docs/<section>/<slug>.md`) it becomes:

```markdown
---
title: "Tmux"
date: 2026-07-25
tags: ["tmux", "terminal", "keybindings"]
source: doc/pages/tools/tmux.md
source_sha: f4a94940e7ff
---

> Tmux keybindings. Prefix is Ctrl+S.

Ghostty starts tmux for every window...

## Custom bindings
```

Section for section, slug for slug. `doc/pages/tools/tmux.md` becomes
`content/docs/tools/tmux.md` and is served at `/docs/tools/tmux/`. One source
page is one site page — never split or merge, because the 1:1 path mapping is
what keeps the next sync's diff honest.

## Front matter

| Key | Value |
|---|---|
| `title` | The H1, humanised. Keep established capitalisation: `SSH`, `tmux`, `Neovim`, `systemd`, `.NET`, `PipeWire`, `journalctl`. Turn a slug into prose: `installed-packages` → `Installed packages`, `wpf-apphost` → `WPF apphost`. |
| `date` | The source's last-commit date: `git -C ~/Dotfiles log -1 --format=%ad --date=short -- <path>`. This keeps the home page's "Recent Docs" meaningful — it shows when the note was actually last worked on. |
| `tags` | 2–4 lowercase tags. First the section (`docker`, `shell`, `sway`), then the subject (`compose`, `aliases`, `keybindings`). These feed search; keep them predictable rather than clever. |
| `source` | Path relative to the dotfiles root: `doc/pages/tools/tmux.md`. **Required** — `audit.sh` finds nothing without it. |
| `source_sha` | `sha256sum <file> \| cut -c1-12` of the source. **Required** — this is how staleness is detected. |

## Body

1. **Drop the H1.** `layouts/_default/single.html` already renders
   `<h1>{{ .Title }}</h1>`, so keeping it prints the title twice.
2. **Keep the `>` lead blockquote.** It reads as a standfirst under the title and
   is the one-line answer to "what is this page".
3. **Leave everything else alone.** Same prose, same code fences, same tables.
   This is a mirror, not an edit pass: rewriting content here means the site and
   the dotfiles drift, and the next sync cannot tell an intentional edit from a
   stale copy. Fix the wording in the dotfiles instead, and re-sync.
4. Hugo's Goldmark has `unsafe = true`, so inline HTML in a source page survives.
   ` ```mermaid ` fences render natively via the site's codeblock hook.

## Links

Relative `.md` links must be rewritten — Hugo serves pretty URLs and a bare
`display.md` 404s.

| In the dotfiles | In the site |
|---|---|
| `[display](display.md)` | `[display](/docs/system/display/)` |
| `[pkglist](../tools/pkglist.md)` | `[pkglist](/docs/tools/pkglist/)` |
| `[guide](../dev/authoring-shell-utilities.md)` | `[guide](/docs/dev/authoring-shell-utilities/)` |

Absolute site paths, not relative ones: they are immune to the page later moving
into a bundle (`<slug>/index.md`), which silently changes what `../` means.

**A link to a page on the skip list must be de-linked**, not left dangling —
replace it with its plain text and keep the sentence reading naturally:

```diff
- See [installed-packages](../system/installed-packages.md) for the full list.
+ See the package inventory kept in the dotfiles for the full list.
```

Check this in both directions: publishing a page can also *fix* a de-linked
reference in an already-published page, and that page's `source_sha` is unchanged,
so nothing will flag it. Grep for the slug across `content/docs/` when a
previously skipped page becomes publishable.

## Sibling files

When a page references a non-markdown file next to it in the dotfiles — 
`dev/authoring-shell-utilities.md` mentions `utility-template.sh` — publish the
page as a **page bundle** so the reader can actually fetch it:

```
content/docs/dev/authoring-shell-utilities/
  index.md              ← the page, front matter unchanged
  utility-template.sh   ← copied from doc/pages/dev/
```

and link it from the prose: ``copy [`utility-template.sh`](utility-template.sh)``.
Relative asset paths work as-is inside a bundle. Scan the asset itself before
copying it — the security policy applies to every byte published, not only to
markdown.

Skip the bundle when the referenced file is itself on the skip list (the package
inventory `.txt` files are, along with their page).

## New sections

A section directory needs an `_index.md` or Hugo will not render its listing:

```markdown
---
title: "Docker"
---
```

Title-case the section name, matching the existing `system/_index.md` style.
Sections needed for a full mirror: `dev`, `docker`, `dotnet`, `shell`, `sway`,
`system` (exists), `tools`, `waybar`.

## Verify before committing

```bash
hugo --minify --quiet && echo "build ok"
```

A Hugo build failure is almost always malformed front matter — an unescaped
quote in a title, or a `date` Hugo cannot parse. Fix it before the commit, not
after: the whole point of one-commit-per-article is that every commit is
independently revertable, and a commit that breaks the build is not.
