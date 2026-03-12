---
title: "Site Workflow"
date: 2026-03-12
tags: ["meta", "hugo"]
---

## Creating content

New docs live under `content/docs/<section>/`. Available sections: `vim/`, `tmux/`, `system/`. Create a new section by adding a folder with an `_index.md` inside.

Create a new page with the Hugo CLI:

```bash
# Standard page (Overview + Details sections pre-filled)
hugo new content docs/<section>/<slug>.md

# Minimal page (front matter only)
hugo new content --kind simple docs/<section>/<slug>.md
```

The file name becomes the URL slug. Edit the generated file — `title`, `date`, and `tags` are set automatically.

### Front matter reference

```yaml
---
title: "My Title"
date: 2026-03-12
tags: ["tag1", "tag2"]
---
```

### Mermaid diagrams

Use a fenced code block with the `mermaid` language tag. The JS is injected only on pages that use it.

### Inline SVGs

```
{{</* svg "path/to/file.svg" "optional-css-class" */>}}
```

The path is relative to the `static/` directory.

## Local preview

```bash
hugo server
```

Opens at `http://localhost:1313`. Live-reloads on file changes.

## Deployment

Push to `main` — GitHub Actions builds and deploys automatically via SFTP to OVH.

To upgrade Hugo: edit `.hugo-version` with the new version number. The CI workflow reads it and caches the binary by version.
