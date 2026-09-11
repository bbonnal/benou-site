---
title: "Java GUI installers"
date: 2026-09-11
tags: ["system", "java", "sway"]
source: doc/pages/system/java.md
source_sha: 25c164e1efb2
---

> Running a Java GUI installer.

- Needed to make a Java GUI installer launch under sway:
  `_JAVA_AWT_WM_NONREPARENTING=1 ./installer.sh`
