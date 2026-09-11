---
name: sync-dotfiles-docs
description: Mirror ~/Dotfiles/doc/pages onto the public Hugo site at docs.bonnal.ch — report what is missing or stale, security-review every candidate page before it goes online, then publish one commit per article so any single article can be reverted on its own. Use when asked to sync, publish, or update the site from the dotfiles, or to check what the site is missing.
---

# Sync dotfiles docs to the site

The site is a mirror of `~/Dotfiles/doc/pages`. One source page is one site page,
same section, same slug. The dotfiles are the source of truth; the site never
holds content that does not exist there.

Publishing is one-way — the site is public and indexed — so the security review
happens before the push, and the user approves the publish list.

## 1. Audit

```bash
.claude/skills/sync-dotfiles-docs/scripts/audit.sh
```

Reports every source page as `MISSING` / `STALE` / `SYNCED` / `SKIPPED`, plus
`ORPHANED` (published, source deleted) and `UNTRACKED` (hand-written, never from
dotfiles). Then pattern-scans the missing and stale ones for credentials, real
identifiers, and machine details. `--all` rescans published pages too;
`--dotfiles` / `--site` override the paths.

`SKIPPED` comes from `skip-list.tsv` next to this file: pages already reviewed and
decided against, each with its reason. They are not scanned and not re-litigated,
which is what keeps `MISSING` meaning "something new to look at" — so a routine run
should report `missing 0`. Deleting a line there does not publish the page; it just
returns it to the review queue.

Read the inventory back to the user as a count and a shape ("31 system pages, 11
docker, 8 shell…"), not as 75 lines of raw output.

## 2. Review every candidate

Read `references/security-policy.md`, then **read each candidate page in full**.
The scan is a net for things with a known shape; the read is the actual review.
Give every page one verdict:

- **PUBLISH** — nothing identifies the person, the machine, or the network.
- **SKIP** — carries something specific that should not be online. Leave it
  unpublished, add a line to `skip-list.tsv` with the reason, and move on. Do not
  redact the copy on the site and publish it anyway.
- **BLOCK** — a real credential. Tell the user at once; a secret already in a git
  repo needs rotating, not just deleting.

Most scan hits are noise: `POSTGRES_PASSWORD=dev` in docker teaching material,
`192.168.1.100` in an `ip addr` example, `/home/jo` as an invented user. The
question is never "does this look like a secret" but **"is this value real, and
is it this person's?"**

**When the page is fine but one value is not, fix the dotfiles instead.** That is
the better outcome than a permanent skip: the carrier name in `system/wwan.md` and
a `services.AddCobaltServices()` call in `dotnet/wpf-apphost.md` both ended up
published this way — one cleared by the user, one stripped at the source and
committed in `~/Dotfiles`. A skip is for when the *page* is the problem, not a
line in it.

## 3. Handle collisions and untracked pages

A source page may collide with a hand-written site page — on the same path, or on
the same topic under a different slug (`docker/installation.md` against the site's
existing `system/install-docker.md`). Never overwrite or silently duplicate one:
report the pair and let the user choose which wins. Hand-written pages carry no
`source:` field, which is exactly how `audit.sh` tells them apart — preserve that.

**Already done — the `vim/` and `tmux/` fold-in.** Those sections were removed on
the first sync; their hand-written pages now live at `tools/vim-shortcuts.md`,
`tools/vim-learnings.md` and `tools/tmux-shortcuts.md`, alongside the mirrored
`tools/nvim.md` and `tools/tmux.md`. They carry no `source:` field on purpose.
Do not recreate `vim/` or `tmux/`.

Still open, if the user ever wants it: merging that hand-written content **into the
dotfiles source pages** so each topic has exactly one source of truth. That edits a
second repo, so show the diff and get approval first, and give it its own commit in
`~/Dotfiles`.

## 4. Get approval before writing anything

Present three lists — PUBLISH (by section), SKIP (each with its one-line reason),
BLOCK (if any) — and ask the user to confirm. This is the gate: everything after
it is public and effectively permanent.

## 5. Convert and build

Follow `references/conversion.md`: front matter with `source` and `source_sha`,
H1 dropped, lead blockquote kept, body otherwise untouched, relative `.md` links
rewritten to `/docs/<section>/<slug>/`, links to skipped pages de-linked, new
sections given an `_index.md`.

Do not improve the prose while mirroring. A site page that differs from its source
is drift the next audit cannot distinguish from staleness. Fix wording in the
dotfiles and re-sync.

```bash
hugo --minify --quiet && echo "build ok"
```

Build must pass before any commit — a commit that breaks the build is not
independently revertable, which defeats the whole commit scheme.

## 6. Commit one article per commit, push once

Scaffolding first, so article commits stay pure:

```bash
git add content/docs/*/_index.md && git commit -m "Add section indexes for dotfiles mirror"
```

Check `git diff --cached --stat` before each commit. A `git mv` or `git rm` from an
earlier step is *already staged*, and a later `git add` will sweep it into the wrong
commit — which breaks the one-article-one-commit property the whole scheme rests on.

Then one commit per article, containing only that article (and its bundle assets):

```bash
git add content/docs/tools/tmux.md
git commit -m "$(cat <<'EOF'
Publish tools/tmux

Mirrors doc/pages/tools/tmux.md @ f4a94940e7ff.
Revert this commit alone to remove the article.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

Then a single push at the end:

```bash
git push
```

One push, not one per article — `.github/workflows` deploys on every push to
`main`, so pushing per commit would fire dozens of builds for one sync. The
commits stay individually revertable either way, which is what granularity was
for.

## 7. Report

Tell the user:

- what was published, by section, with the commit count
- what was skipped and why — one line each, so the list is easy to argue with
- anything blocked, and that it needs rotating
- that removing a single article is `git revert <sha> && git push`

Re-run `audit.sh` after the push: everything published should now read `SYNCED`,
and the remainder should be exactly the skip list.
