---
title: "Vim learnings"
date: 2025-12-21
tags: ["vim", "learnings"]
---

## Insert the date

This method uses the date coreutis command

### Default date

```bash
:read !date
Sun Dec 21 01:24:39 PM CET 2025
```

### Minimal date
```bash
:read !date +\%F
2025-12-21
```

Backslash seem necessary to have the command be correctly interpreted

### Date and time
```bash
:read !date +\%F\ \%T
2025-12-21 13:35:47
```


## Numbering stuffs

This method uses the nl (number line) coreutils command 

```
 First item
 Second item
 Third item

with the text selected

:<,'>!nl -w1 -s.

1. First item
2. Second item
3. Third item

```


## Listing files

This method uses the wc (word count) coreutils command

```
:read !wc -l -w -m ~/Repos/benou-site/content/docs/* | sort -n

wc: /home/benou/Repos/benou-site/content/docs/template-page: Is a directory
      0       0       0 /home/benou/Repos/benou-site/content/docs/template-page
     25      92     509 /home/benou/Repos/benou-site/content/docs/shortcuts-tmux.md
     32     137     630 /home/benou/Repos/benou-site/content/docs/shortcuts-vim.md
     32      64     486 /home/benou/Repos/benou-site/content/docs/install-docker.md
     50      95     575 /home/benou/Repos/benou-site/content/docs/vim-learnings.md
    108     288    2204 /home/benou/Repos/benou-site/content/docs/my-new-post.md
    791    3969   26473 /home/benou/Repos/benou-site/content/docs/arch-install.md
   1038    4645   30877 total
```


## Find and replace


I need to replace the word kangaroo everywhere the word kangaroo appears. Kangaroo has to be replaced with koala.
If there are many kangaroos, those have to be replaced with just as many koalas.



```

:<,'>s/kangaroo/koala/gIc

g : all instances in each line
I : only instances with same case
c : confirm each replacement

I need to replace the word koala everywhere the word koala appears. Kangaroo has to be replaced with koala.
If there are many koalas, those have to be replaced with just as many koalas.

```

one would have to change the capitalized Kangaroos in a second pass


```
Manual method

ciw   at the location of kangaroo write koala

move to next kangaroo 

repaeat action with .

I need to replace the word koala everywhere the word koala appears. koala has to be replaced with koala.
If there are many koala, those have to be replaced with just as many koalas.
```

### Putting yanked text in the search register

```
yank the text

/

<C -r>

search the text text text

navigate the results with n and N

```


