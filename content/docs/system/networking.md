---
title: "Networking"
date: 2026-05-23
tags: ["system", "networking", "nmcli"]
source: doc/pages/system/networking.md
source_sha: 8e310dfcca1a
---

> ip, ss, DNS, NetworkManager, systemd-networkd, nftables, and diagnostics.

## ip — interfaces & addresses

- All interfaces:
  `ip a`

- One interface:
  `ip addr show enp0s3`

- IPv4 only:
  `ip -4 addr`

- Brief one-liner:
  `ip -br addr` / `ip -br link`

- Stats:
  `ip -s link show enp0s3`

- Add IP (temporary):
  `sudo ip addr add 192.168.1.100/24 dev enp0s3`

- Remove IP:
  `sudo ip addr del 192.168.1.100/24 dev enp0s3`

- Flush all:
  `sudo ip addr flush dev enp0s3`

- Up / down:
  `sudo ip link set enp0s3 up` / `down`

- Set MTU:
  `sudo ip link set enp0s3 mtu 9000`

- Add VLAN:
  `sudo ip link add link enp0s3 name enp0s3.100 type vlan id 100`

## ip — routing

- Routing table:
  `ip r`

- Default route:
  `ip route show default`

- Add static route:
  `sudo ip route add 10.0.0.0/8 via 192.168.1.1`

- Add default gateway:
  `sudo ip route add default via 192.168.1.1`

- Delete:
  `sudo ip route del 10.0.0.0/8`

- Trace which route applies:
  `ip route get 8.8.8.8`

- ARP / neighbor table:
  `ip neigh`

## ss — sockets

- TCP listeners + process:
  `ss -tlnp`

- UDP listeners + process:
  `ss -ulnp`

- All TCP+UDP:
  `ss -tunap`

- Established TCP:
  `ss -t state established`

- By source/dest port:
  `ss -tnp sport = :443`
  `ss -tnp dport = :443`

- By process name:
  `ss -tnp | grep nginx`

- Unix sockets:
  `ss -xlnp`

- Summary:
  `ss -s`

| Flag | Meaning |
|------|---------|
| `-t` | TCP |
| `-u` | UDP |
| `-l` | listening |
| `-a` | all |
| `-n` | numeric |
| `-p` | show process |
| `-s` | summary |

## DNS — dig

- Lookup:
  `dig example.com`
  `dig example.com +short`

- Record type:
  `dig example.com MX`
  `dig example.com AAAA`
  `dig example.com TXT`

- Use specific server:
  `dig @8.8.8.8 example.com`

- Reverse lookup:
  `dig -x 8.8.8.8`

- Trace resolution path:
  `dig +trace example.com`

## DNS — simpler

- `host example.com`
- `host -t MX example.com`
- `nslookup example.com`

## resolvectl (systemd-resolved)

- Status:
  `resolvectl status`

- Query:
  `resolvectl query example.com`

- Flush cache:
  `sudo resolvectl flush-caches`

- Stats:
  `resolvectl statistics`

- Current servers:
  `resolvectl dns`

| File | Purpose |
|------|---------|
| `/etc/resolv.conf` | system DNS (often managed) |
| `/etc/hosts` | static mappings |
| `/etc/nsswitch.conf` | resolution order |
| `/etc/systemd/resolved.conf` | resolved config |

## NetworkManager (nmcli)

- General status:
  `nmcli general status`

- All connections:
  `nmcli connection show`

- Active connections:
  `nmcli connection show --active`

- Device status:
  `nmcli device status`

- Device details:
  `nmcli device show enp0s3`

### WiFi

- List networks:
  `nmcli device wifi list`

- Connect:
  `nmcli device wifi connect "SSID" password "password"`

- Hidden network:
  `nmcli device wifi connect "SSID" password "password" hidden yes`

- Disconnect:
  `nmcli device disconnect wlan0`

### Static IP connection

```
nmcli connection add con-name "static-eth" ifname enp0s3 type ethernet \
    ipv4.addresses 192.168.1.100/24 \
    ipv4.gateway 192.168.1.1 \
    ipv4.dns "8.8.8.8,8.8.4.4" \
    ipv4.method manual
```

- Modify:
  `nmcli connection modify "static-eth" ipv4.dns "1.1.1.1"`

- Up / down:
  `nmcli connection up "static-eth"` / `down`

- Delete:
  `nmcli connection delete "static-eth"`

- Reload from disk:
  `nmcli connection reload`

- Show saved WiFi passwords:
  `sudo grep -r psk= /etc/NetworkManager/system-connections/`

## systemd-networkd

Config in `/etc/systemd/network/`.

- DHCP wired example, `20-wired.network`:
  ```
  [Match]
  Name=enp0s3

  [Network]
  DHCP=yes
  ```

- Static example:
  ```
  [Network]
  Address=192.168.1.100/24
  Gateway=192.168.1.1
  DNS=8.8.8.8
  ```

- Enable:
  ```
  sudo systemctl enable --now systemd-networkd
  sudo systemctl enable --now systemd-resolved
  ```

- Status:
  `networkctl status` / `networkctl list`

- Reload without restart:
  `sudo networkctl reload`

## nftables

- Show ruleset:
  `sudo nft list ruleset`

- Flush:
  `sudo nft flush ruleset`

- List tables / chains:
  `sudo nft list tables`
  `sudo nft list table inet filter`

- Load config:
  `sudo nft -f /etc/nftables.conf`

- Enable on boot:
  `sudo systemctl enable --now nftables`

- Add rule on the fly:
  `sudo nft add rule inet filter input tcp dport 8080 accept`

- Find handle to delete:
  `sudo nft -a list chain inet filter input`
  `sudo nft delete rule inet filter input handle 12`

- Block IP:
  `sudo nft add rule inet filter input ip saddr 10.0.0.5 drop`

- Rate-limit SSH:
  `sudo nft add rule inet filter input tcp dport 22 ct state new limit rate 3/minute accept`

- Minimal stateful firewall, `/etc/nftables.conf`:
  ```
  table inet filter {
      chain input {
          type filter hook input priority 0; policy drop;
          ct state established,related accept
          iifname "lo" accept
          ip protocol icmp accept
          ip6 nexthdr icmpv6 accept
          tcp dport 22 accept
          tcp dport { 80, 443 } accept
          log prefix "[nft-drop] " drop
      }
      chain forward { type filter hook forward priority 0; policy drop; }
      chain output  { type filter hook output  priority 0; policy accept; }
  }
  ```

## Diagnostics

- Ping:
  `ping -c 4 8.8.8.8`

- IPv6 ping:
  `ping -c 4 -6 google.com`

- Traceroute (numeric, faster):
  `traceroute -n google.com`

- MTR (live + report):
  `mtr google.com` / `mtr -r -c 10 google.com`

- Port open check:
  `nc -zv 192.168.1.1 22`

- Scan range w/ timeout:
  `nc -zv -w3 192.168.1.1 80-100`

- Public IP:
  `curl -4 icanhazip.com`
  `curl -6 icanhazip.com`

- Per-iface bandwidth:
  `ip -s link`

- iftop (per-connection):
  `sudo iftop -i enp0s3`

- Packet capture:
  `sudo tcpdump -i enp0s3 -c 100`
  `sudo tcpdump -i enp0s3 port 80 -w capture.pcap`

- ARP scan local net:
  `sudo arp-scan --localnet`

- Wake on LAN:
  `wol AA:BB:CC:DD:EE:FF`

## Useful files

| Path | Purpose |
|------|---------|
| `/etc/hostname` | system hostname |
| `/etc/hosts` | static host mappings |
| `/etc/resolv.conf` | DNS resolver |
| `/etc/nsswitch.conf` | name resolution order |
| `/etc/nftables.conf` | firewall rules |
| `/etc/NetworkManager/` | NM config + connections |
| `/etc/systemd/network/` | networkd config |
| `/etc/systemd/resolved.conf` | resolved config |
