---
title: "SSH"
date: 2026-05-23
tags: ["system", "ssh", "rsync"]
source: doc/pages/system/ssh.md
source_sha: ff4d4cb2f7ba
---

> SSH keys, config, tunnels, agent, rsync/scp, sshd hardening.

## Keys

- Generate Ed25519 (recommended):
  `ssh-keygen -t ed25519 -C "jo@hostname"`

- RSA 4096 (if Ed25519 unsupported):
  `ssh-keygen -t rsa -b 4096 -C "jo@hostname"`

- Custom path:
  `ssh-keygen -t ed25519 -f ~/.ssh/mykey`

- Change passphrase:
  `ssh-keygen -p -f ~/.ssh/id_ed25519`

- Fingerprint (SHA256 default):
  `ssh-keygen -lf ~/.ssh/id_ed25519.pub`

- MD5 fingerprint:
  `ssh-keygen -lf ~/.ssh/id_ed25519.pub -E md5`

## Deploy public key

- Easy:
  `ssh-copy-id user@host`

- Specific key:
  `ssh-copy-id -i ~/.ssh/mykey.pub user@host`

- Manual:
  `cat ~/.ssh/id_ed25519.pub | ssh user@host "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"`

## ~/.ssh/config

```
Host *
    AddKeysToAgent yes
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host myserver
    HostName 192.168.1.100
    User jo
    Port 2222
    IdentityFile ~/.ssh/mykey

Host internal
    HostName 10.0.0.5
    User jo
    ProxyJump bastion

Host bastion
    HostName bastion.example.com
    User jo
    IdentityFile ~/.ssh/bastion_key

Host *.dev.example.com
    User deployer
    IdentityFile ~/.ssh/dev_key

Host *
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600
```

- Sockets dir for multiplexing:
  `mkdir -p ~/.ssh/sockets`

- Test resolved config:
  `ssh -G myserver`

## Tunnels

- Local forward (local:8080 → remote:80):
  `ssh -L 8080:localhost:80 user@remote`

- Through bastion to internal db:
  `ssh -L 5432:db.internal:5432 user@remote`

- Remote forward (remote:9090 → local:3000):
  `ssh -R 9090:localhost:3000 user@remote`

- SOCKS5 proxy on local:1080:
  `ssh -D 1080 user@remote`

- Background (no shell):
  `ssh -fNL 8080:localhost:80 user@remote`

- Kill background tunnel:
  `pkill -f "ssh -fN.*8080"`

## ssh-agent

- Start manually:
  `eval "$(ssh-agent -s)"`

- Add key:
  `ssh-add ~/.ssh/id_ed25519`

- Add with timeout:
  `ssh-add -t 3600 ~/.ssh/id_ed25519`

- List loaded:
  `ssh-add -l`

- Remove one / all:
  `ssh-add -d ~/.ssh/id_ed25519` / `ssh-add -D`

- Agent forwarding (use local key from remote):
  `ssh -A user@bastion`

> **Warning:** Agent forwarding (`-A`) exposes keys to the remote admin. Prefer `ProxyJump` when possible.

## Common operations

- Basic:
  `ssh user@host`

- Custom port:
  `ssh -p 2222 user@host`

- Single remote command:
  `ssh user@host "uname -a"`

- With TTY (e.g. sudo):
  `ssh -t user@host "sudo systemctl restart nginx"`

- Pipe in (push):
  `cat backup.sql | ssh user@host "psql -d mydb"`
  `tar czf - /data | ssh user@host "cat > /backups/data.tar.gz"`

- Pipe out (pull):
  `ssh user@host "tar czf - /data" > data.tar.gz`

- Verbose (debug):
  `ssh -v user@host` (or `-vv`, `-vvv`)

### Escape sequences (after newline)

| Sequence | Action |
|----------|--------|
| `~.` | disconnect hung session |
| `~^Z` | suspend SSH client |
| `~#` | list forwarded connections |
| `~?` | help |

## rsync over SSH

Trailing `/` on source matters: with `/` copies contents, without copies the directory itself.

- Push:
  `rsync -avz /local/dir/ user@host:/remote/dir/`

- Pull:
  `rsync -avz user@host:/remote/dir/ /local/dir/`

- Custom SSH port:
  `rsync -avz -e "ssh -p 2222" /local/dir/ user@host:/remote/dir/`

- Dry run:
  `rsync -avzn /local/dir/ user@host:/remote/dir/`

- Mirror (delete extras on dest):
  `rsync -avz --delete /local/dir/ user@host:/remote/dir/`

- Progress:
  `rsync -avz --progress /local/dir/ user@host:/remote/dir/`

- Bandwidth limit (KB/s):
  `rsync -avz --bwlimit=1000 /local/dir/ user@host:/remote/dir/`

- Resume large file:
  `rsync -avz --partial --progress large-file user@host:/dest/`

- Exclude:
  `rsync -avz --exclude='.git' --exclude='node_modules' src/ user@host:/deploy/`

| Flag | Meaning |
|------|---------|
| `-a` | archive (recursive, perms, times, symlinks, …) |
| `-v` | verbose |
| `-z` | compress |
| `-P` | `--partial --progress` |
| `-n` | dry run |
| `-h` | human-readable sizes |

## scp

- To remote:
  `scp file.txt user@host:/remote/path/`

- From remote:
  `scp user@host:/remote/file.txt /local/path/`

- Recursive:
  `scp -r /local/dir user@host:/remote/`

- Custom port:
  `scp -P 2222 file.txt user@host:/remote/`

- Preserve timestamps:
  `scp -p file.txt user@host:/remote/`

> Prefer rsync for repeated transfers — supports resume, delta, filtering.

## sshd hardening

Edit `/etc/ssh/sshd_config` or drop-in `/etc/ssh/sshd_config.d/`.

```
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
Port 2222
AllowUsers jo admin
AllowGroups wheel ssh-users
MaxAuthTries 3
X11Forwarding no
AllowAgentForwarding no
LoginGraceTime 30
LogLevel VERBOSE

KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
```

- Validate config:
  `sudo sshd -t`

- Apply:
  `sudo systemctl restart sshd`

- Live auth log:
  `journalctl -u sshd -f`

## Required permissions

```
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 600 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/known_hosts
```
