---
title: "Compression"
date: 2026-05-23
tags: ["system", "compression", "tar"]
source: doc/pages/system/compression.md
source_sha: cabcb1f42889
---

> tar, gzip, xz, zstd, zip, 7z. Speed/ratio comparison and parallel compression.

## tar

| Flag | Meaning |
|------|---------|
| `c` | create |
| `x` | extract |
| `t` | list |
| `z` | gzip |
| `J` | xz |
| `j` | bzip2 |
| `f` | filename |
| `v` | verbose |
| `p` | preserve perms |
| `C` | change dir before op |
| `r` | append |
| `--exclude` | skip matches |

- Create gzip:
  `tar czf archive.tar.gz dir/`

- Create xz (best ratio):
  `tar cJf archive.tar.xz dir/`

- Create zstd (best speed/ratio):
  `tar --zstd -cf archive.tar.zst dir/`

- Create bzip2:
  `tar cjf archive.tar.bz2 dir/`

- Verbose:
  `tar czvf archive.tar.gz dir/`

- Preserve perms (backups):
  `tar czpf archive.tar.gz dir/`

- Extract (auto-detects):
  `tar xf archive.tar.gz`

- Extract to dir:
  `tar xf archive.tar.gz -C /target/`

- Extract one file:
  `tar xf archive.tar.gz path/to/file.txt`

- List contents:
  `tar tf archive.tar.gz`

- Diff against filesystem:
  `tar df archive.tar`

- Exclude patterns:
  `tar czf archive.tar.gz --exclude='*.log' --exclude='.git' dir/`

- Exclude from file:
  `tar czf archive.tar.gz --exclude-from=exclude.txt dir/`

- Append (uncompressed only):
  `tar rf archive.tar newfile.txt`

- Progress with pv:
  `tar cf - dir/ | pv | gzip > archive.tar.gz`

- Incremental backup:
  ```
  tar czf full.tar.gz --listed-incremental=snap.snar dir/
  tar czf incr.tar.gz --listed-incremental=snap.snar dir/
  ```

## gzip

- Compress (replaces file):
  `gzip file.txt`

- Keep original:
  `gzip -k file.txt`

- Decompress:
  `gunzip file.txt.gz` / `gzip -d file.txt.gz`

- Level (1 fastest, 9 best):
  `gzip -9 file.txt`

- To stdout:
  `gzip -c file.txt > file.txt.gz`

- View without extracting:
  `zcat file.txt.gz`
  `zless file.txt.gz`
  `zgrep "pattern" file.txt.gz`

- Show compression ratio:
  `gzip -l file.txt.gz`

- Test integrity:
  `gzip -t file.txt.gz`

## xz

- Compress:
  `xz file.txt`

- Keep original:
  `xz -k file.txt`

- Decompress:
  `xz -d file.txt.xz` / `unxz file.txt.xz`

- Level (0–9, default 6):
  `xz -9 file.txt`

- Extreme mode (slightly better):
  `xz -9e file.txt`

- All cores:
  `xz -T0 file.txt`

- View:
  `xzcat file.txt.xz` / `xzless` / `xzgrep`

- Info / test:
  `xz -l file.txt.xz` / `xz -t file.txt.xz`

## zstd

Install `zstd`.

- Compress:
  `zstd file.txt`

- Keep original:
  `zstd -k file.txt`

- Decompress:
  `zstd -d file.txt.zst` / `unzstd file.txt.zst`

- Level (1–19, default 3):
  `zstd -19 file.txt`

- Ultra (up to 22):
  `zstd --ultra -22 file.txt`

- All cores:
  `zstd -T0 file.txt`

- Adaptive level (auto):
  `zstd --adapt file.txt`

- Info / test:
  `zstd -l file.txt.zst` / `zstd -t file.txt.zst`

- Dictionary training (many small similar files):
  ```
  zstd --train /path/to/samples/* -o dict.zstd
  zstd -D dict.zstd file.txt
  ```

## zip / unzip

- Create:
  `zip archive.zip file1.txt file2.txt`

- Recursive:
  `zip -r archive.zip dir/`

- Password protect:
  `zip -e archive.zip files`

- Best compression:
  `zip -9 -r archive.zip dir/`

- Exclude:
  `zip -r archive.zip dir/ -x "*.log" "*.tmp"`

- Update:
  `zip -u archive.zip newfile.txt`

- Extract:
  `unzip archive.zip`

- To dir:
  `unzip archive.zip -d /target/`

- Single file:
  `unzip archive.zip path/to/file.txt`

- Overwrite without prompt:
  `unzip -o archive.zip`

- List / test:
  `unzip -l archive.zip` / `unzip -t archive.zip`

## 7z

Install `p7zip`.

- Create:
  `7z a archive.7z dir/`

- Max compression:
  `7z a -mx=9 archive.7z dir/`

- Password + encrypted filenames:
  `7z a -p -mhe=on archive.7z dir/`

- Create as zip:
  `7z a -tzip archive.zip dir/`

- Extract (preserve dirs):
  `7z x archive.7z`

- To dir:
  `7z x archive.7z -o/target/`

- Flat extract:
  `7z e archive.7z`

- List / test:
  `7z l archive.7z` / `7z t archive.7z`

- Split into volumes:
  `7z a -v100m archive.7z dir/`

- Multi-threaded:
  `7z a -mmt=on archive.7z dir/`

## Comparison (defaults)

| Format | Speed | Ratio | Multi-thread | Notes |
|--------|-------|-------|--------------|-------|
| gzip | fast | good | no (`pigz`) | universal |
| bzip2 | slow | better | no (`pbzip2`) | legacy |
| xz | slow | best | yes (`-T`) | used by pacman |
| zstd | very fast | very good | yes (`-T`) | best tradeoff |
| zip | fast | good | no | Windows-friendly |
| 7z | slow | best | yes | strong encryption |

- Benchmark:
  ```
  time gzip -k -9 testfile
  time xz -k -9 testfile
  time zstd -k -19 testfile
  ls -lh testfile testfile.gz testfile.xz testfile.zst
  ```

## Parallel compression

- pigz (parallel gzip, standard `.gz` output):
  `pigz file.txt`
  `pigz -p 4 file.txt`
  `unpigz file.txt.gz`

- pbzip2:
  `pbzip2 file.txt` / `pbzip2 -d file.txt.bz2`

- With tar (pipe through):
  `tar cf - dir/ | pigz > archive.tar.gz`
  `tar cf - dir/ | zstd -T0 > archive.tar.zst`
