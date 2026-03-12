# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Serve locally with live reload
hugo server

# Build for production
hugo --minify

# Create a new page (standard template)
hugo new content docs/<section>/<slug>.md

# Create a minimal page (front matter only)
hugo new content --kind simple docs/<section>/<slug>.md

# Create a page bundle (for pages with media/PDFs)
mkdir -p content/docs/<section>/<slug>
hugo new content docs/<section>/<slug>/index.md
```

Deployment is automated via GitHub Actions on push to `main` — built with Hugo and deployed via SFTP to OVH. To upgrade Hugo, edit `.hugo-version`.

## Content structure

All docs live in `content/docs/` organized by section subdirectories (`vim/`, `tmux/`, `system/`, `meta/`). Each section has an `_index.md`. To add a new section, create a folder with an `_index.md` inside.

**Page types:**
- **Leaf page** (`docs/section/slug.md`) — single markdown file, no media
- **Page bundle** (`docs/section/slug/index.md`) — folder containing the markdown file plus any media assets (images, plots, PDFs). Use this whenever a page needs attached files.

**Media convention — always use page bundles for media:**
```
content/docs/section/my-page/
  index.md          ← page content
  diagram.png       ← image referenced as ![alt](diagram.png)
  plot.svg          ← SVG referenced via {{< svg >}} shortcode
  guide.pdf         ← PDF referenced via {{< pdf >}} shortcode
```
Hugo copies all non-markdown bundle assets to the output directory, so relative paths (`./file.pdf`, `file.png`) work as-is in the browser.

Archetypes in `archetypes/`:
- `default.md` — standard page with Overview/Details skeleton
- `simple.md` — front matter only (`--kind simple`)

## Architecture

Hugo static site with fully custom templates (no theme), deployed to `docs.bonnal.ch`.

**Search**: Fuse.js client-side full-text search. The index is built at compile time via `layouts/index.json.json`, which serializes all `docs` pages to JSON. Search JS loads only on the home page.

**Mermaid**: A ` ```mermaid ` fenced block triggers `layouts/_default/_markup/render-codeblock-mermaid.html`, which sets a page-level flag — `mermaid.min.js` is then injected in `baseof.html` only on pages that need it.

**SVG shortcode**: `{{< svg "path/to/file.svg" "optional-class" >}}` inlines an SVG from `static/`.

**PDF shortcode**: `{{< pdf src="guide.pdf" title="My Guide" description="Optional subtitle" height="780px" >}}` renders an embedded PDF viewer with a download button. Place the PDF alongside `index.md` in a page bundle and reference it by filename.

**Layout structure:**
- `layouts/_default/baseof.html` — base shell (header, footer, Mermaid injection)
- `layouts/_default/single.html` — individual doc page
- `layouts/_default/list.html` — section listing
- `layouts/partials/head.html` — `<head>` with fonts, CSS, Fuse.js (home only)
- `layouts/partials/search.html` — search UI (home page only)
- `layouts/index.html` — home page
