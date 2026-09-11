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

Reports every source page as `MISSING` / `STALE` / `SYNCED`, plus `ORPHANED`
(published, source deleted) and `UNTRACKED` (hand-written, never from dotfiles).
Then pattern-scans the missing and stale ones for credentials, real identifiers,
and machine details. `--all` rescans published pages too; `--dotfiles` / `--site`
override the paths.

Read the inventory back to the user as a count and a shape ("31 system pages, 11
docker, 8 shell…"), not as 75 lines of raw output.

## 2. Review every candidate

Read `references/security-policy.md`, then **read each candidate page in full**.
The scan is a net for things with a known shape; the read is the actual review.
Give every page one verdict:

- **PUBLISH** — nothing identifies the person, the machine, or the network.
- **SKIP** — carries something specific that should not be online. Leave it
  unpublished and list it. Do not redact and publish.
- **BLOCK** — a real credential. Tell the user at once; a secret already in a git
  repo needs rotating, not just deleting.

Most scan hits are noise: `POSTGRES_PASSWORD=dev` in docker teaching material,
`192.168.1.100` in an `ip addr` example, `/home/jo` as an invented user. The
question is never "does this look like a secret" but **"is this value real, and
is it this person's?"**

Known SKIP cases in the current dotfiles, as worked examples:

- `system/installed-packages.md` — real hostname `bbhost` plus an exact
  1499-package inventory. Fingerprints the machine and advertises its software
  versions. Its `.txt` siblings skip with it.
- `system/arch-install.md` — names the actual laptop (`Lenovo T14s`) and this
  machine's disk layout. The site already publishes a fuller, hand-written
  arch-install guide, so nothing is lost by skipping it.
- `system/wwan.md` — names the mobile carrier, which narrows country and account.

## 3. Handle collisions and untracked pages

A source page may collide with a hand-written site page — on the same path, or on
the same topic under a different slug (`docker/installation.md` against the site's
existing `system/install-docker.md`). Never overwrite or silently duplicate one:
report the pair and let the user choose which wins. Hand-written pages carry no
`source:` field, which is exactly how `audit.sh` tells them apart — preserve that.

**First run only — folding `vim/` and `tmux/` into `tools/`.** The site has
hand-written `vim/shortcuts.md`, `vim/learnings.md` and `tmux/shortcuts.md` that
overlap the dotfiles `tools/nvim.md` and `tools/tmux.md`. One topic should have
one home, and that home is the dotfiles:

1. Propose merging the hand-written content **into the dotfiles source pages**,
   showing the user the exact diff first.
2. On approval, commit that in `~/Dotfiles` — it is their repo, so it gets its own
   commit and its own mention in the report.
3. Mirror the merged pages to `content/docs/tools/`, and `git rm` the now-empty
   `content/docs/vim/` and `content/docs/tmux/` sections.

If the user declines the merge, move the hand-written pages to
`content/docs/tools/vim-shortcuts.md` etc. without a `source:` field, so they stay
visibly hand-written and the mirror stays 1:1.

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
