---
title: "Install Docker on Ubuntu"
date: 2025-11-01
tags: ["docker", "installation", "ubuntu"]
---

## Installation Steps

### 1. Update package index

```bash
sudo apt update
```

### 2. Install dependencies

```bash
sudo apt install apt-transport-https ca-certificates curl software-properties-common
```

### 3. Install Docker

```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io
```

### 4. Verify installation

```bash
sudo docker run hello-world
```
