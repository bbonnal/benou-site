---
title: "Git"
date: 2026-05-23
tags: ["tools", "git", "version-control"]
source: doc/pages/tools/git.md
source_sha: 42fb6e5cae33
---

> Daily workflow, branching, remotes, undo, stash, tags, advanced.

## Initial setup

```
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
git config --global core.editor vim
git config --global color.ui auto
git config --global pull.rebase true
```

- Useful aliases:
  ```
  git config --global alias.st status
  git config --global alias.co checkout
  git config --global alias.br branch
  git config --global alias.ci commit
  git config --global alias.lg "log --oneline --graph --decorate -20"
  ```

- Show config + origin:
  `git config --list`
  `git config --list --show-origin`

## Daily workflow

- Status:
  `git status` / `git status -s`

- Stage file / dir:
  `git add file.txt`
  `git add src/`

- Interactive (per-hunk):
  `git add -p`

- Modified + deleted (not new untracked):
  `git add -u`

- Commit:
  `git commit -m "message"`
  `git commit`
  `git commit -am "message"`

### Diff

- Unstaged:
  `git diff`

- Staged:
  `git diff --staged`

- Since last commit:
  `git diff HEAD`

- Branch vs branch:
  `git diff main..feature`

- Summary:
  `git diff --stat`

### Log

- Full:
  `git log`

- Compact:
  `git log --oneline`

- Graph + all branches:
  `git log --oneline --graph --all`

- Last 20:
  `git log --oneline -20`

- By author / date / message:
  `git log --author="jo"`
  `git log --since="2025-01-01"`
  `git log --grep="fix"`

- File history with renames:
  `git log -p --follow file.txt`

### Show / blame

- Show commit:
  `git show abc1234`
  `git show HEAD~3`

- Blame:
  `git blame file.txt`
  `git blame -L 10,20 file.txt`

## Branching

- List local / remote / all:
  `git branch`
  `git branch -r`
  `git branch -a`
  `git branch -v`

- Create:
  `git branch feature-x`

- Create + switch (modern):
  `git switch -c feature-x`

- Switch:
  `git switch main`

- Rename:
  `git branch -m old new`
  `git branch -m new`            # current

- Delete (safe):
  `git branch -d feature-x`

- Force delete:
  `git branch -D feature-x`

### Merge

- Merge:
  `git checkout main && git merge feature-x`

- Force merge commit (preserve branch history):
  `git merge --no-ff feature-x`

- Abort:
  `git merge --abort`

### Rebase

- Onto main:
  `git checkout feature-x && git rebase main`

- Abort / continue:
  `git rebase --abort` / `git rebase --continue`

## Remotes

- List:
  `git remote -v`

- Add:
  `git remote add origin https://github.com/user/repo.git`
  `git remote add upstream https://github.com/original/repo.git`

- Remove / rename:
  `git remote remove origin`
  `git remote rename origin old-origin`

### Fetch / pull / push

- Fetch:
  `git fetch origin`
  `git fetch --all`

- Pull:
  `git pull`
  `git pull --rebase`

- Push:
  `git push`
  `git push origin main`

- Push + set upstream:
  `git push -u origin feature-x`

- Delete remote branch:
  `git push origin --delete feature-x`

- Push all branches / tags:
  `git push --all origin`
  `git push --tags`

### Track / prune

- Track remote branch:
  `git checkout --track origin/feature-x`

- Set upstream:
  `git branch --set-upstream-to=origin/main main`

- Sync fork with upstream:
  ```
  git fetch upstream
  git checkout main
  git merge upstream/main
  git push origin main
  ```

- Prune stale refs:
  `git fetch --prune`
  `git remote prune origin`

## Undo

### Unstage / discard

- Unstage file:
  `git restore --staged file.txt`

- Discard local changes:
  `git restore file.txt`

- Discard all:
  `git restore .`

### Amend

- Change message:
  `git commit --amend -m "new message"`

- Add forgotten file:
  `git add forgotten.txt && git commit --amend --no-edit`

### Revert (safe on shared branches)

- New commit undoing old commit:
  `git revert abc1234`

### Reset

- Soft (keep changes staged):
  `git reset --soft HEAD~1`

- Mixed (keep changes unstaged, default):
  `git reset --mixed HEAD~1`

- Hard (destructive!):
  `git reset --hard HEAD~1`

### Recover lost commits

- Show reflog:
  `git reflog`

- Check out lost commit:
  `git checkout abc1234`

- Save it:
  `git branch recovery abc1234`

### Remove files

- Untrack, keep on disk:
  `git rm --cached file.txt`

- Untrack + delete:
  `git rm file.txt`

## Stash

- Save (staged + unstaged):
  `git stash`
  `git stash push -m "description"`

- Include untracked / ignored:
  `git stash -u`
  `git stash -a`

- Apply (keep in list):
  `git stash apply`

- Pop (apply + remove):
  `git stash pop`

- Specific stash:
  `git stash apply stash@{2}`

- List / show:
  `git stash list`
  `git stash show -p stash@{0}`

- Drop / clear:
  `git stash drop stash@{1}`
  `git stash clear`

- Branch from stash:
  `git stash branch new-branch stash@{0}`

## Tags

- List:
  `git tag`
  `git tag -l "v1.*"`

- Annotated (recommended):
  `git tag -a v1.0 -m "Release v1.0"`

- Lightweight:
  `git tag v1.0`

- Tag specific commit:
  `git tag -a v0.9 abc1234 -m "Retroactive"`

- Show:
  `git show v1.0`

- Delete:
  `git tag -d v1.0`
  `git push origin --delete v1.0`

- Push:
  `git push origin v1.0`
  `git push --tags`

## Cherry-pick

- Apply one commit:
  `git cherry-pick abc1234`

- Stage only (no commit):
  `git cherry-pick --no-commit abc1234`

- Range:
  `git cherry-pick abc1234..def5678`

- Abort:
  `git cherry-pick --abort`

## Worktrees

- Add existing branch:
  `git worktree add ../feature-x feature-x`

- New branch + worktree:
  `git worktree add -b hotfix ../hotfix main`

- List:
  `git worktree list`

- Remove / prune:
  `git worktree remove ../feature-x`
  `git worktree prune`

## Bisect

- Start + mark current bad + known good:
  ```
  git bisect start
  git bisect bad
  git bisect good v1.0
  ```

- Then iterate:
  `git bisect good` or `git bisect bad`

- Reset when done:
  `git bisect reset`

- Automated:
  ```
  git bisect start HEAD v1.0
  git bisect run ./test-script.sh
  ```

## Interactive rebase

- Last 5 commits:
  `git rebase -i HEAD~5`

Commands in the editor:
- `pick` — keep
- `reword` — change message
- `edit` — stop to amend
- `squash` — merge into previous (keep both messages)
- `fixup` — merge into previous (discard message)
- `drop` — remove

## Submodules

- Add:
  `git submodule add https://github.com/user/repo.git path/to/sub`

- Clone with submodules:
  `git clone --recurse-submodules URL`

- Initialize after clone:
  `git submodule update --init --recursive`

- Update to latest on tracked branch:
  `git submodule update --remote`

- Remove (3-step):
  ```
  git submodule deinit path/to/submodule
  git rm path/to/submodule
  rm -rf .git/modules/path/to/submodule
  ```

## Useful patterns

- File history with diffs:
  `git log -p --follow file.txt`

- When was string added/removed:
  `git log -S "searchString" --oneline`

- When did regex appear:
  `git log -G "regex" --oneline`

- All tracked files:
  `git ls-files`

- File at specific revision:
  `git show HEAD~3:path/to/file.txt`

- Tar archive of HEAD:
  `git archive --format=tar.gz --prefix=project/ HEAD > project.tar.gz`

- Clean untracked:
  `git clean -nd`            # dry run
  `git clean -fd`            # for real

- Shallow clone:
  `git clone --depth 1 URL`

- Sparse checkout:
  ```
  git sparse-checkout init
  git sparse-checkout set src/ docs/
  ```

## .gitignore

```gitignore
# Compiled
*.o
*.pyc
__pycache__/
build/
dist/

# Dependencies
node_modules/
vendor/

# Secrets
.env
.env.local
*.pem

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
Thumbs.db

# Logs
*.log

# Un-ignore
!important.log
```

- Check why a file is ignored:
  `git check-ignore -v file.txt`

- Global ignore:
  `git config --global core.excludesFile ~/.config/git/ignore`
