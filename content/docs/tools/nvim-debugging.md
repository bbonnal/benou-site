---
title: "Neovim debugging"
date: 2026-07-04
tags: ["tools", "neovim", "dap"]
source: doc/pages/tools/nvim-debugging.md
source_sha: 1d6b50a5a811
---

> Debug workflows: python local + docker attach, launch.json, C/C++, C#.
> Keybindings: see `nvim`. Full guide: `doc/nvim/README.md`.

## How it works

`<leader>db` sets a breakpoint, `<leader>dc` starts and shows a picker with
every config for the filetype — built-ins plus the project's
`.vscode/launch.json` (read automatically). The debug UI opens with the
session and closes when it ends.

Adapters are mason-installed: debugpy (python), codelldb (C/C++),
netcoredbg (C#).

## Python: local

- Venv is auto-detected (`$VIRTUAL_ENV` or `.venv/` in project root);
  activate before launching nvim when in doubt.

- Run current file:
  `<leader>dc` → pick `file` (or `file:args` for arguments)

- Debug the pytest under cursor:
  `<leader>dm` (method) / `<leader>dM` (class)

## Python: docker attach

- In the container, run the app under debugpy with the port published:
  `python -m debugpy --listen 0.0.0.0:5678 --wait-for-client app.py`
  (`docker run ... -p 5678:5678`; --wait-for-client blocks until attach)

- Attach:
  `<leader>dc` → `Attach remote (docker/debugpy)`
  Prompts with defaults: host `127.0.0.1`, port `5678`, container root `/app`.

- Container root = directory holding the code INSIDE the container.
  Wrong root → breakpoints show hollow and never hit (#1 failure).

- Use `127.0.0.1`, not `localhost` (can resolve to IPv6 and refuse).

## Pin per-project: .vscode/launch.json

Picked up automatically by `<leader>dc`, no config needed:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Attach my-service",
      "type": "debugpy",
      "request": "attach",
      "connect": { "host": "127.0.0.1", "port": 5678 },
      "pathMappings": [
        { "localRoot": "${workspaceFolder}", "remoteRoot": "/app" }
      ],
      "justMyCode": false
    }
  ]
}
```

## C / C++

- Build with debug info (`-g`, or platformio debug build).
- `<leader>dc` → codelldb config → enter path to the executable.

## C#

- `dotnet build` (Debug configuration).
- `<leader>dc` → netcoredbg config → point at `bin/Debug/<tfm>/<project>.dll`.
