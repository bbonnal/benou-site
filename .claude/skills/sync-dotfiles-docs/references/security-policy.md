# Security policy — what may go online

The site is public at `https://docs.bonnal.ch`. Everything published here is
world-readable, indexed by search engines, and effectively permanent: a page
removed later may still live in caches and archives. So the decision to publish
is one-way, and the bar is *before* the push, not after.

## The one allowed identifier

**`benou`** — the pseudonym — is cleared for publication. Every other identifier
that ties a page to the real person or the real machine is not:

| Never online | Why |
|---|---|
| `bbhost` (real hostname) | names the actual machine |
| `bbonnal` (git handle) | links the docs to the real account |
| `benjamin`, `bonnal`, real email | the actual identity |
| real filesystem/disk UUIDs, MAC addresses, device serials | fingerprints the hardware |
| LAN addressing that is *this* network | maps the home network |
| WiFi SSIDs and PSKs | locates the person |
| employer, client names, colleagues' names | not the author's to publish |

**Cleared by the user, do not re-flag:**

- Monitor serial numbers (`VTN45266`, `VTN45265` in the sway pages) — display-panel
  identifiers, not account or network identifiers.
- The mobile carrier name in `system/wwan.md`. The site's own `.ch` domain already
  says as much about location as the carrier does.
- The laptop's model/SKU code (`21M1000PMZ` in `system/suspend-resume.md`). It
  names a configuration that thousands of units share, not a single machine —
  unlike a unit serial, which stays on the never-online list.

`audit.sh` derives the identity terms from the live machine (`hostname`, `$USER`,
`git config user.name` / `user.email`), so an `IDENT` hit is never a coincidence —
it is that exact value, in that page.

## Three verdicts

Every page reviewed gets exactly one.

### PUBLISH
Read the whole page and found nothing that identifies the person, the machine,
or the network; nothing that weakens a real system's security by being known.
Generic examples, invented placeholders and documentation *about* secrets are all
fine here.

### SKIP
The page is fine in principle but carries something specific that should not be
online. **Leave it unpublished, list it in the report, and move on.** Do not
redact and publish — a redacted page invites a second judgement call on every
future sync, and the whole point of the skip list is that it stays stable and
obvious. If the user later wants a skipped page online, they can edit the source
in the dotfiles and the next sync will pick it up clean.

Typical SKIP cases:

- **Machine fingerprints** — `system/installed-packages.md` carries the real
  hostname *and* an exact 1499-package inventory. Either alone is identifying;
  the version list also advertises which unpatched software runs on the machine.
- **Real network topology** — a page showing the actual LAN layout, static leases,
  or a reachable host.
- **Personal circumstance** — what the machine is *used for*, where that is
  financial, medical or administrative rather than technical. `system/java.md`
  once named the tax software behind its workaround; the workaround itself is
  generic, so the name was stripped in the dotfiles and the page publishes.
- **A third party's name** — a client, employer or internal project appearing in
  an example (a `services.AddCobaltServices()` call in a DI snippet). Not the
  author's to publish. The fix is usually to strip the name in the dotfiles, not
  to withhold the page.
- **The author's own security posture in operational detail** — a page that
  describes how *this* machine is locked down specifically enough to plan around
  (exact LUKS slot layout with recovery specifics, backup repo locations plus
  their unlock procedure, which TPM PCRs are bound). General technique is fine
  and already published; this machine's configuration is not.

### BLOCK
A real credential, key, or token. Never published, never negotiated, and worth
telling the user about immediately and plainly — because a secret that reached a
git repo, even a private one, should be rotated rather than merely deleted.

## A scan hit is a question, not a verdict

`audit.sh` fires on shapes, not on meaning. Expect and dismiss:

- `POSTGRES_PASSWORD=dev`, `DB_PASSWORD=correcthorsebatterystaple` — docker docs
  teaching how env vars work. Invented values in teaching material.
- `192.168.1.100`, `10.0.0.5`, `8.8.8.8` — textbook addresses in `ip`/`ssh`/`nmcli`
  examples.
- `/home/jo`, `/home/me`, `/home/appuser` — invented users in examples.
- `AA:BB:CC:DD:EE:FF` — a placeholder MAC.
- Whole pages *about* secret handling (`tools/usb-helper-elevation.md`,
  `docker/security-rootless.md`). These are threat-model write-ups of the user's
  own published tooling. Documenting how a password is *kept safe* leaks nothing;
  that is a security document, and it is the good kind.

The distinguishing question is always the same: **is this value real, and is it
this person's?** A pattern hit on an invented value is noise. The same pattern on
a live value is the reason the scan exists.

## The scan is a net, not the review

Read every page you are about to publish, top to bottom. The scan catches shapes
it knows; it cannot catch a sentence like "the spare key is under the third
flowerpot", an inline comment naming a client, or a screenshot path that reveals
a project name. The read is the review. The scan just makes sure the read does
not miss the mechanical things.

## Link integrity

A published page must never link to a skipped one — that is a 404 for the reader
and a signpost to something deliberately withheld. When a page you are publishing
links to a page on the skip list, replace the link with its plain text and keep
the sentence readable. `conversion.md` covers the mechanics.
