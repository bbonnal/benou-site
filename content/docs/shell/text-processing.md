---
title: "Text processing"
date: 2026-05-23
tags: ["shell", "sed", "awk"]
source: doc/pages/shell/text-processing.md
source_sha: 410d4def7cd6
---

> sed, awk, cut, sort, uniq, tr, xargs, column, paste, wc, tee.

## sed

### Substitute

- First on each line:
  `sed 's/foo/bar/' file.txt`

- All on each line:
  `sed 's/foo/bar/g' file.txt`

- Case-insensitive:
  `sed 's/foo/bar/gi' file.txt`

- In-place edit:
  `sed -i 's/foo/bar/g' file.txt`

- In-place with backup:
  `sed -i.bak 's/foo/bar/g' file.txt`

### Target lines

- Single line:
  `sed '5s/foo/bar/' file.txt`

- Range:
  `sed '10,20s/foo/bar/g' file.txt`

- From pattern to EOF:
  `sed '/START/,$ s/foo/bar/g' file.txt`

- Between patterns:
  `sed '/BEGIN/,/END/ s/foo/bar/g' file.txt`

### Delete lines

- One line:
  `sed '5d' file.txt`

- Range:
  `sed '10,20d' file.txt`

- Comments:
  `sed '/^#/d' file.txt`

- Empty lines:
  `sed '/^$/d' file.txt`

### Insert / append / replace

- Insert before line 3:
  `sed '3i\New line' file.txt`

- Append after line 3:
  `sed '3a\New line' file.txt`

- Before pattern:
  `sed '/pattern/i\Inserted' file.txt`

- Replace matched line:
  `sed '/pattern/c\Replacement' file.txt`

### Print specific lines (-n + p)

- Like grep:
  `sed -n '/pattern/p' file.txt`

- Line 5:
  `sed -n '5p' file.txt`

- Range:
  `sed -n '10,20p' file.txt`

### Multiple ops, alt delimiter

- Multiple ops:
  `sed -e 's/foo/bar/g' -e 's/baz/qux/g' file.txt`

- Alt delimiter (paths):
  `sed 's|/usr/local|/opt|g' file.txt`
  `sed 's#http://#https://#g' file.txt`

### Capture groups

- Basic regex (escape parens):
  `sed 's/\(.*\)=\(.*\)/\2=\1/' file.txt`

- Extended (`-E`):
  `sed -E 's/(.*)=(.*)/\2=\1/' file.txt`

### Line trim / prefix / suffix

- Prefix:
  `sed 's/^/PREFIX: /' file.txt`

- Suffix:
  `sed 's/$/ # comment/' file.txt`

- Trim leading WS:
  `sed 's/^[[:space:]]*//' file.txt`

- Trim trailing WS:
  `sed 's/[[:space:]]*$//' file.txt`

- Both:
  `sed 's/^[[:space:]]*//;s/[[:space:]]*$//' file.txt`

### Transliteration (like tr)

- `sed 'y/abc/ABC/' file.txt`

## awk

### Print fields

`$1`, `$2`, … `$0` is the line. `$NF` is last, `$(NF-1)` second-to-last.

- One col:
  `awk '{print $1}' file.txt`

- Two cols:
  `awk '{print $1, $3}' file.txt`

- Last col:
  `awk '{print $NF}' file.txt`

### Field separators

- Colon input:
  `awk -F: '{print $1, $3}' /etc/passwd`

- CSV:
  `awk -F',' '{print $2}' data.csv`

- Custom output separator:
  `awk -F: -v OFS='\t' '{print $1, $3, $7}' /etc/passwd`

### Filter with patterns

- Contains "error":
  `awk '/error/' file.txt`

- Not starting with #:
  `awk '!/^#/' file.txt`

- Numeric compare:
  `awk '$3 > 100' file.txt`

- String compare:
  `awk '$1 == "root"' /etc/passwd`

- UID ≥ 1000:
  `awk -F: '$3 >= 1000' /etc/passwd`

### Built-in vars

| Var | Meaning |
|-----|---------|
| `NR` | line number (across all files) |
| `FNR` | line number (current file) |
| `NF` | fields on current line |
| `FS/OFS` | input/output field separator |
| `RS/ORS` | input/output record separator |

- Number lines:
  `awk '{print NR, $0}' file.txt`

- Count lines:
  `awk 'END {print NR}' file.txt`

- Long lines:
  `awk 'length > 80' file.txt`

- Between patterns (inclusive):
  `awk '/START/,/END/' file.txt`

- Skip header:
  `awk 'NR > 1 {print $2}' data.tsv`

### Aggregation

- Sum col:
  `awk '{sum += $3} END {print sum}' data.txt`

- Average:
  `awk '{sum += $1; n++} END {print sum/n}' nums.txt`

- Max of col 3:
  `awk 'NR==1 || $3 > max {max=$3} END {print max}' data.txt`

- Frequency count (e.g. requests per IP):
  `awk '{count[$1]++} END {for (k in count) print count[k], k}' access.log | sort -rn`

### Printf formatting

- Aligned columns:
  `awk -F: '{printf "%-20s %s\n", $1, $7}' /etc/passwd`

- Replace fields:
  `awk -F: -v OFS=':' '$3 == 0 {$1 = "SUPERUSER"} {print}' /etc/passwd`

- Multiple rules:
  `awk '/error/ {errors++} /warning/ {warnings++} END {print errors, warnings}' log.txt`

## cut

- By char range:
  `cut -c1-10 file.txt`

- From char 5:
  `cut -c5- file.txt`

- First 20 chars:
  `cut -c-20 file.txt`

- One delimited field:
  `cut -d: -f1 /etc/passwd`

- Multiple fields:
  `cut -d: -f1,3,7 /etc/passwd`

- Field range:
  `cut -d',' -f2-4 data.csv`

- Complement (everything except):
  `cut -d: --complement -f2 /etc/passwd`

- Change output delimiter:
  `cut -d: -f1,7 --output-delimiter=$'\t' /etc/passwd`

## sort

- Alphabetic:
  `sort file.txt`

- Reverse:
  `sort -r file.txt`

- Numeric:
  `sort -n numbers.txt`

- Human (K/M/G):
  `sort -h sizes.txt`

- Version (1.10 > 1.2):
  `sort -V versions.txt`

- Month names:
  `sort -M dates.txt`

- Random shuffle:
  `sort -R file.txt`

- Unique:
  `sort -u file.txt`

- Case-insensitive:
  `sort -f file.txt`

- Already sorted? (exit code):
  `sort -c file.txt`

- Stable sort:
  `sort -s -k2,2 file.txt`

### By column (-k)

- 2nd col:
  `sort -k2 file.txt`

- Numeric on 2nd col only:
  `sort -k2,2n file.txt`

- By UID in passwd:
  `sort -t: -k3,3n /etc/passwd`

- Multi-key:
  `sort -k1,1 -k2,2n file.txt`

- IPs correctly:
  `sort -t. -k1,1n -k2,2n -k3,3n -k4,4n ips.txt`

## uniq

uniq compares **adjacent** lines — always `sort` first.

- Dedupe:
  `sort file.txt | uniq`

- Count occurrences:
  `sort file.txt | uniq -c`

- Only duplicates:
  `sort file.txt | uniq -d`

- Only unique (appear once):
  `sort file.txt | uniq -u`

- Case-insensitive:
  `sort file.txt | uniq -i`

- Skip first N fields/chars:
  `sort file.txt | uniq -f 1`
  `sort file.txt | uniq -s 5`

- Top 10 most frequent:
  `sort file.txt | uniq -c | sort -rn | head -10`

## tr

- Lower → upper:
  `echo "hello" | tr 'a-z' 'A-Z'`

- Spaces → underscores:
  `echo "hello world" | tr ' ' '_'`

- Tabs → spaces:
  `cat file.txt | tr '\t' ' '`

- Squeeze repeats:
  `echo "aabbcc" | tr -s 'a-z'`           # abc

- Squeeze spaces:
  `echo "too   many" | tr -s ' '`

- Delete chars:
  `echo "hello 123" | tr -d '0-9'`

- Complement (invert set, keep only):
  `echo "hello 123" | tr -cd '0-9\n'`

- Strip non-printable:
  `cat file.bin | tr -cd '[:print:]\n'`

- DOS → Unix line endings:
  `tr -d '\r' < dosfile.txt > unixfile.txt`

| Class | Matches |
|-------|---------|
| `[:alnum:]` | letters + digits |
| `[:alpha:]` | letters |
| `[:digit:]` | digits |
| `[:lower:]` | lowercase |
| `[:upper:]` | uppercase |
| `[:space:]` | whitespace |
| `[:print:]` | printable |
| `[:punct:]` | punctuation |

## xargs

- Pass stdin as args:
  `find . -name "*.txt" | xargs wc -l`

- Null-separated (handles spaces):
  `find . -name "*.txt" -print0 | xargs -0 wc -l`

- Batch size:
  `echo "1 2 3 4 5" | xargs -n 2 echo`

- Placeholder `{}`:
  `ls *.tar.gz | xargs -I {} tar xzf {} -C /tmp/extracted/`

- Per-line:
  `cat urls.txt | xargs -I {} curl -O {}`

- Parallel (4 procs):
  `find . -name "*.png" -print0 | xargs -0 -P 4 -n 1 optipng`

- Prompt before each:
  `find . -name "*.bak" | xargs -p rm`

- Dry run (echo before exec):
  `find . -name "*.log" | xargs -t echo rm`

- Bulk find-and-replace:
  `grep -rl "TODO" src/ | xargs sed -i 's/TODO/DONE/g'`

## column

- Auto-align:
  `mount | column -t`

- Table with delimiter:
  `cat /etc/passwd | column -t -s ':'`

- Vertical list → multi-col:
  `echo -e "one\ntwo\nthree\nfour\nfive\nsix" | column`

- Custom output separator:
  `column -t -s ',' -o ' | ' data.csv`

- JSON (util-linux 2.37+):
  `echo '{"a":1,"b":2}' | column --json`

## paste

- Side-by-side (tab):
  `paste file1.txt file2.txt`

- Custom delimiter:
  `paste -d ',' file1.txt file2.txt`

- All lines into one:
  `paste -s file.txt`

- All lines with delimiter:
  `paste -sd ',' file.txt`

- Lines → N columns:
  `paste - - - < file.txt`              # 3 cols
  `cat file.txt | paste -d ',' - -`     # 2 cols, comma

- Reorder columns (from same file):
  `paste <(cut -f3 data.tsv) <(cut -f1 data.tsv)`

## wc

- Lines / words / chars:
  `wc file.txt`

- Lines:
  `wc -l file.txt`

- Words:
  `wc -w file.txt`

- Chars / bytes:
  `wc -m file.txt` / `wc -c file.txt`

- Longest line length:
  `wc -L file.txt`

- Count files in dir:
  `ls | wc -l` / `fd -t f | wc -l`

- Total lines across files:
  `find . -name "*.py" -exec cat {} + | wc -l`

## tee

- Write + pass through:
  `ls -la | tee listing.txt`

- Append:
  `echo "new entry" | tee -a log.txt`

- Multiple files at once:
  `echo "hello" | tee file1.txt file2.txt`

- Inspect mid-pipeline:
  `cat data.txt | sort | tee sorted.txt | uniq -c | tee counts.txt | sort -rn | head`

- Write to sudo-owned file:
  `echo "new line" | sudo tee -a /etc/hosts > /dev/null`

## Common combinations

- HTTP status code frequency:
  `awk '{print $9}' access.log | sort | uniq -c | sort -rn`

- Unique IPs:
  `awk '{print $1}' access.log | sort -u`

- Max in CSV col 3:
  `awk -F',' '{print $3}' data.csv | sort -n | tail -1`

- Bulk find-and-replace:
  `grep -rl "oldtext" src/ | xargs sed -i 's/oldtext/newtext/g'`

- Dedupe preserving order (no sort):
  `awk '!seen[$0]++' file.txt`

- Extract `key=value`:
  `grep -oP '(?<=key=)\w+' config.txt`

- Numbered list:
  `cat -n file.txt`
  `awk '{printf "%3d. %s\n", NR, $0}' file.txt`

- Join matching line with next:
  `sed '/pattern/{N;s/\n/ /}' file.txt`

- Every Nth line:
  `awk 'NR % 5 == 0' file.txt`

- Sorted diff:
  `diff <(sort file1.txt) <(sort file2.txt)`
