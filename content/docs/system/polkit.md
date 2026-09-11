---
title: "polkit"
date: 2026-07-25
tags: ["system", "polkit", "privileges"]
source: doc/pages/system/polkit.md
source_sha: f579ac27e140
---

> Polkit authentication agent — fuzzel prompts for your password when an
> action needs elevated privileges.

## What runs

- Agent script: `~/.config/sway/scripts/fuzzel-polkit-agent.sh`
- Started by sway: `exec ~/.config/sway/scripts/fuzzel-polkit-agent.sh`
- When polkit needs authentication, a `fuzzel` password prompt appears.
  Type your password and Enter; press Escape (empty) to cancel.

## How it works

- `cmd-polkit-agent` registers as the polkit agent and talks JSON over a pipe.
- The script parses each request with `jq`, shows a `fuzzel --dmenu --password`
  prompt, and replies `authenticate` (with the password) or `cancel`.
- Appearance follows your normal `~/.config/fuzzel/fuzzel.ini` theme.

## Dependencies

  jq              official repo   (installed)
  fuzzel          official repo   (installed)
  cmd-polkit-git  AUR             `yay -S cmd-polkit-git`  <- provides cmd-polkit-agent

## Customizing the prompt

- Extra args are passed straight to fuzzel. Edit the `exec` line in
  `~/.config/sway/config`, e.g. highlight the prompt in red:
  `exec ~/.config/sway/scripts/fuzzel-polkit-agent.sh --prompt-color=ff0000ff`

## Testing

- Confirm the agent is running first (it is only started by sway's `exec`):
  `pgrep -af cmd-polkit-agent`
  Nothing printed? Reload sway ($mod+Shift+c), or start it by hand:
  `~/.config/sway/scripts/fuzzel-polkit-agent.sh &`
- Trigger a prompt without rebooting:
  `pkexec true`   (runs /bin/true as root — a self-contained auth request;
  or `systemctl restart <unit>` for a service you own)
- Test one specific action and force the prompt:
  `pkcheck --action-id <id> --process $$ --allow-user-interaction`
  (`pkaction` lists every registered action ID)

## Notes / troubleshooting

- Only one polkit agent should run per session. This replaced the previous
  `polkit-gnome` agent (`/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1`).
- No prompt appears? Confirm `cmd-polkit-git` is installed and reload sway
  (`$mod+Shift+c`), then re-test with `pkexec true`.
- Source (vendored, MIT): https://codeberg.org/lukeflo/fuzzel-polkit-agent
