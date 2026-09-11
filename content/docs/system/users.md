---
title: "Users and permissions"
date: 2026-05-23
tags: ["system", "users", "permissions"]
source: doc/pages/system/users.md
source_sha: 960a83d5405b
---

> Users, groups, file permissions, ACLs, sudoers, PAM.

## Create / modify users

- New user with home + bash + wheel group:
  `sudo useradd -m -G wheel -s /bin/bash newuser`

- Specific UID and home:
  `sudo useradd -m -u 1500 -d /home/custom -s /bin/zsh newuser`

- System user (no login):
  `sudo useradd -r -s /usr/bin/nologin serviceuser`

- Set password:
  `sudo passwd newuser`

- Change own password:
  `passwd`

- Add to extra groups (always `-aG`):
  `sudo usermod -aG wheel,docker newuser`

- Change shell:
  `sudo usermod -s /bin/zsh newuser`

- Rename:
  `sudo usermod -l newname oldname`

- Move home (creates + moves contents):
  `sudo usermod -d /new/home -m newuser`

- Lock / unlock account:
  `sudo usermod -L newuser` / `-U`

- Delete (keep home):
  `sudo userdel newuser`

- Delete + remove home + mail spool:
  `sudo userdel -r newuser`

> **Warning:** Always use `-aG` (append) with `usermod`. Bare `-G` replaces all supplementary groups — can lock you out of sudo.

## Inspect users

- Current user info:
  `id`

- Specific user:
  `id newuser`

- Logged in:
  `who` / `w`

- All users:
  `getent passwd`

- Groups for user:
  `groups newuser`

- Change own login shell:
  `chsh -s /bin/zsh`

## Password expiry (chage)

- Show:
  `sudo chage -l newuser`

- Expire after 90 days:
  `sudo chage -M 90 newuser`

- Expire on date:
  `sudo chage -E 2025-12-31 newuser`

- Force change at next login:
  `sudo chage -d 0 newuser`

## Groups

- Create:
  `sudo groupadd developers`

- With GID:
  `sudo groupadd -g 2000 developers`

- Remove user from group:
  `sudo gpasswd -d newuser developers`

- Change primary group:
  `sudo usermod -g developers newuser`

- Delete:
  `sudo groupdel developers`

- List members:
  `getent group wheel`

## chmod — symbolic

- Add execute for owner:
  `chmod u+x script.sh`

- Remove write for group/others:
  `chmod go-w file.txt`

- Set exactly (owner rw, group r):
  `chmod u=rw,g=r,o= file.txt`

- Everyone read:
  `chmod a+r file.txt`

- Capital `X` = execute only when already executable / on dirs:
  `chmod -R u=rwX,g=rX,o= /project`

- Separate dirs vs files:
  ```
  find . -type d -exec chmod 755 {} +
  find . -type f -exec chmod 644 {} +
  ```

## chmod — octal

| # | bits | Permission |
|---|------|-----------|
| 0 | `---` | none |
| 1 | `--x` | execute |
| 2 | `-w-` | write |
| 3 | `-wx` | write + execute |
| 4 | `r--` | read |
| 5 | `r-x` | read + execute |
| 6 | `rw-` | read + write |
| 7 | `rwx` | all |

- Examples:
  ```
  chmod 755 script.sh
  chmod 644 file.txt
  chmod 600 secret.txt
  chmod 700 dir/
  chmod 775 shared_dir/
  ```

## chmod — special bits

- SUID (run as file owner):
  `chmod u+s /usr/bin/program` / `chmod 4755 ...`

- SGID (run as group; on dirs, files inherit group):
  `chmod g+s /shared/dir` / `chmod 2775 ...`

- Sticky bit (only owner can delete in dir, e.g. /tmp):
  `chmod +t /tmp` / `chmod 1777 /tmp`

- Find SUID/SGID files:
  ```
  find / -perm /4000 -type f 2>/dev/null    # SUID
  find / -perm /2000 -type f 2>/dev/null    # SGID
  ```

## chown

- Change owner:
  `sudo chown newuser file.txt`

- Owner + group:
  `sudo chown newuser:developers file.txt`

- Group only:
  `sudo chown :developers file.txt` or `chgrp developers file.txt`

- Recursive:
  `sudo chown -R newuser:developers /project`

- Conditional on current owner:
  `sudo chown --from=olduser newuser file.txt`

- Copy ownership from another file:
  `sudo chown --reference=source.txt target.txt`

## ACLs

`ls -l` shows `+` after permissions when ACLs are set.

- View:
  `getfacl file.txt`

- View recursively:
  `getfacl -R /project`

- Grant per-user read+write:
  `setfacl -m u:jo:rw file.txt`

- Grant per-group:
  `setfacl -m g:developers:rx /project`

- Default ACL (inherited by new files in dir):
  `setfacl -d -m g:developers:rwx /project`

- Recursive:
  `setfacl -R -m g:developers:rx /project`

- Remove entry:
  `setfacl -x u:jo file.txt`

- Remove all ACLs:
  `setfacl -b file.txt`

- Copy ACLs:
  `getfacl source.txt | setfacl --set-file=- target.txt`

## sudoers

Always edit via `visudo` (validates before saving).

- Edit main:
  `sudo visudo`

- Drop-in (preferred):
  `sudo visudo -f /etc/sudoers.d/myuser`

- Common rules:
  ```
  jo ALL=(ALL:ALL) ALL                                    # full sudo with password
  jo ALL=(ALL:ALL) NOPASSWD: ALL                          # full sudo no password
  jo ALL=(ALL) /usr/bin/pacman, /usr/bin/systemctl        # specific commands only
  %wheel ALL=(ALL:ALL) ALL                                # group rule
  jo ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx
  jo ALL=(postgres) /usr/bin/psql                         # run as specific user
  ```

- List allowed:
  `sudo -l`

- Run as another user:
  `sudo -u postgres psql`

- Safer edit (drops privileges after opening):
  `sudoedit /etc/hosts`

## PAM

Config in `/etc/pam.d/`. Common files: `system-auth`, `system-login`, `su`, `sudo`, `sshd`.

- Require wheel for `su`, add to `/etc/pam.d/su`:
  `auth required pam_wheel.so use_uid`

- Failed login lockout (`/etc/security/faillock.conf`):
  ```
  deny = 5
  unlock_time = 600
  ```

- Show failed attempts:
  `faillock --user jo`

- Reset:
  `sudo faillock --user jo --reset`

- Password requirements (`/etc/security/pwquality.conf`):
  ```
  minlen = 12
  dcredit = -1
  ucredit = -1
  ```

- Resource limits (`/etc/security/limits.conf`):
  ```
  jo           hard  nofile  65535
  @developers  soft  nproc   4096
  ```

## Key files

| File | Purpose |
|------|---------|
| `/etc/passwd` | accounts (name, UID, GID, home, shell) |
| `/etc/shadow` | password hashes + expiry |
| `/etc/group` | group definitions |
| `/etc/gshadow` | encrypted group passwords |
| `/etc/sudoers` | sudo rules (edit with `visudo`) |
| `/etc/sudoers.d/` | drop-in sudo rules |
| `/etc/login.defs` | default UID ranges, password aging |
| `/etc/skel/` | skeleton home dir |
| `/etc/pam.d/` | PAM config |
| `/etc/security/` | limits, faillock, pwquality |
