---
name: nmap
description: |
  Nmap workflow lengkap dari recon dasar sampai advanced evasion.
  Kata kunci: nmap, port scan, service detection, os fingerprint, nse scripts, scan techniques, firewalk, traceroute.
---

# SKILL: Nmap — Full Spectrum Port Scanning

> **Trigger:** User minta scan port, service detection, os fingerprint, atau recon jaringan.

---

## 0. Setup & cheat sheet

```bash
# Install
apt install nmap -y          # Linux
brew install nmap             # macOS
choco install nmap            # Windows

# Update scripts
nmap --script-updates
```

---

## 1. Scan Techniques — Pilih Sesuai Kebutuhan

| Technique | Flag | Kapan Pakai |
|-----------|------|-------------|
| TCP SYN | `-sS` | Default, cepat, stealth (butuh root) |
| TCP Connect | `-sT` | Tanpa root, tapi noisy |
| UDP | `-sU` | Cek DNS, SNMP, TFTP, NTP |
| TCP ACK | `-sA` | Map firewall rules |
| Window | `-sW` | OS fingerprint tanpa SYN |
| TCP Null | `-sN` | Evasion firewall |
| TCP FIN | `-sF` | Evasion firewall |
| Xmas | `-sX` | Evasion firewall (FIN+PSH+URG) |

---

## 2. Pre-Scan Recon

```bash
# Live host discovery (sebelum port scan)
nmap -sn 192.168.1.0/24                    # Ping sweep
nmap -sn -PE 192.168.1.0/24                # ICMP echo
nmap -sn -PA80,443 192.168.1.0/24          # TCP ACK host discovery
nmap -sn -PS22,80,443 192.168.1.0/24       # TCP SYN host discovery
nmap -sn -PU53 192.168.1.0/24              # UDP host discovery
nmap -sn -PY139,445 192.168.1.0/24         # SCTP host discovery
nmap -sL 192.168.1.0/24                    # List scan (no port)

# DNS brute force
nmap --script dns-brute target.com

# Reverse DNS
nmap -R 192.168.1.1-50
```

---

## 3. Port Scanning — Level Progressif

### Level 1: Quick Scan
```bash
nmap -T4 target                    # Top 1000 ports, fast
nmap -T4 -F target                 # Top 100 ports
nmap -T4 --top-ports 20 target    # Top 20 ports
```

### Level 2: Full Scan
```bash
nmap -sS -p- target                # All 65535 TCP ports
nmap -sS -p 1-10000 target        # Custom range
nmap -sU --top-ports 100 target   # Top 100 UDP
```

### Level 3: Aggressive
```bash
nmap -sS -p- -T4 --min-rate 1000 target   # Fast full scan
nmap -sS -p- -T5 --max-retries 2 target   # Ultra fast (miss-prone)
nmap -sU -p- -T4 target                   # All UDP (SLOW)
```

---

## 4. Service & OS Detection

```bash
# Service version detection
nmap -sV target                    # Basic version
nmap -sV --version-all target     # All probes
nmap -sV -sC target               # Version + default scripts

# OS detection
nmap -O target                     # OS fingerprint
nmap -O --osscan-guess target     # Aggressive OS guess
nmap -A target                     # Aggressive: -sV -O -sC --traceroute

# Combined (recommended)
nmap -sV -sC -O -p- target       # Full info all ports
```

---

## 5. NSE Scripts — The Real Power

### Script Categories

| Category | Flag | Untuk |
|----------|------|-------|
| Default | `-sC` | Equivalent `--script=default` |
| Safe | `--script=safe` | Tidak aggressive |
| Vuln | `--script=vuln` | Cek vulnerability |
| Exploit | `--script=explore` | Coba exploit |
| Auth | `--script=auth` | Cek auth bypass |
| Brute | `--script=brute` | Brute force |
| Discovery | `--script=discovery` | Enum service info |
| Dos | `--script=dos` | DoS testing (HATI-HATI!) |
| Malware | `--script=malware` | Cek malware/backdoor |

### Popular Scripts

```bash
# Web
nmap --script=http-title,http-server-header,http-headers target
nmap --script=http-enum target                    # Directory enumeration
nmap --script=http-put -p 80 target               # Test HTTP PUT
nmap --script=http-shellshock -p 80 target        # Shellshock
nmap --script=http-sql-injection target            # SQLi detection
nmap --script=http-xss target                     # XSS detection
nmap --script=http-vmware-path-disclosure target  # VMware info leak

# SSL/TLS
nmap --script=ssl-enum-ciphers -p 443 target      # Cipher enumeration
nmap --script=ssl-heartbleed -p 443 target        # Heartbleed
nmap --script=ssl-poodle -p 443 target            # POODLE
nmap --script=ssl-cert -p 443 target              # Certificate info

# SMB
nmap --script=smb-enum-shares -p 445 target       # SMB shares
nmap --script=smb-enum-users -p 445 target        # SMB users
nmap --script=smb-vuln-ms17-010 -p 445 target     # EternalBlue
nmap --script=smb-vuln-ms08-067 -p 445 target     # Conficker

# SSH
nmap --script=ssh-auth-methods -p 22 target       # Auth methods
nmap --script=ssh2-enum-algos -p 22 target        # Algorithms

# DNS
nmap --script=dns-brute target                    # Subdomain brute
nmap --script=dns-zone-transfer -p 53 target      # Zone transfer

# MySQL
nmap --script=mysql-info -p 3306 target           # MySQL info
nmap --script=mysql-enum -p 3306 target           # MySQL enum

# Vulnerability
nmap --script=vuln target                         # All vuln scripts
nmap --script="vuln and not dos" target           # Vuln tanpa DoS
```

### Custom Script Execution

```bash
# Single script
nmap --script=http-title target

# Multiple scripts
nmap --script=http-title,http-server-header target

# Script with arguments
nmap --script=http-brute --script-args http-brute.path=/admin target

# Script with threads
nmap --script=http-brute --script-args http-brute.threads=10 target

# Exclude scripts
nmap --script="not dos and not brute" target
```

---

## 6. Firewall/IDS Evasion

```bash
# Fragmentation
nmap -f target                    # Fragment packets
nmap -ff target                   # More fragmentation
nmap -f -f target                 # Even more

# MTU
nmap --mtu 24 target              # Custom MTU (must be multiple of 8)

# Decoys
nmap -D RND:10 target             # 10 random decoys
nmap -D ME,192.168.1.100 target   # Decoy + real IP
nmap -D 192.168.1.1,192.168.1.2,ME target  # Specific decoys

# Source spoofing
nmap -S 192.168.1.100 target      # Spoof source IP
nmap -e eth0 -S 192.168.1.100 target  # Specify interface

# Port spoofing
nmap --source-port 53 target      # Spoof source port (DNS)
nmap --source-port 88 target      # Spoof source port (Kerberos)

# Timing
nmap -T0 target                   # Paranoid (IDS evasion)
nmap -T1 target                   # Sneaky
nmap -T2 target                   # Polite
nmap -T3 target                   # Normal (default)
nmap -T4 target                   # Aggressive
nmap -T5 target                   # Insane

# Custom timing
nmap --min-parallelism 10 target
nmap --max-parallelism 250 target
nmap --min-hostgroup 50 target
nmap --max-hostgroup 256 target
nmap --min-rtt-timeout 100ms target
nmap --max-rtt-timeout 3000ms target
nmap --initial-rtt-timeout 500ms target
nmap --host-timeout 30m target
nmap --max-retries 2 target
nmap --min-rate 1000 target
nmap --max-rate 10000 target

# Idle scan
nmap -sI zombie_host:port target  # Zombie-based idle scan

# CSS (Closed/Open/SYN/FIN)
nmap --scanflags SYNACKRST target # Custom flags
```

---

## 7. Output Formats

```bash
# Normal
nmap -oN scan.txt target

# XML (for tools)
nmap -oX scan.xml target

# Grepable
nmap -oG scan.gnmap target

# All formats
nmap -oA scan_results target

# Script kiddie
nmap -oS scan_scriptkid target
```

---

## 8. Real-World Workflow

### Workflow: Full Assessment

```
TARGET DITERIMA
│
├─→ FASE 1: HOST DISCOVERY
│   nmap -sn -PE -PA22,80,443 TARGET/24
│   Output: live hosts list
│
├─→ FASE 2: PORT SCAN
│   nmap -sS -p- --min-rate 1000 TARGET
│   Output: open ports
│
├─→ FASE 3: SERVICE DETECTION
│   nmap -sV -sC -p OPEN_PORTS TARGET
│   Output: service versions
│
├─→ FASE 4: OS DETECTION
│   nmap -O --osscan-guess TARGET
│   Output: OS fingerprint
│
├─→ FASE 5: VULN SCAN
│   nmap --script=vuln -p OPEN_PORTS TARGET
│   Output: vulnerabilities
│
├─→ FASE 6: DEEP ENUM
│   nmap --script=discovery -p SPECIFIC_PORTS TARGET
│   Output: detailed service info
│
└─→ FASE 7: REPORT
    nmap -oA assessment TARGET
    Gabung semua output
```

### Workflow: CTF Quick

```bash
# 1. Quick recon
nmap -sV -sC -T4 target

# 2. If specific port found
nmap -sV -sC -p PORT target

# 3. Vuln check
nmap --script=vuln -p PORT target

# 4. Deep enum per service
nmap --script=smb-enum-shares -p 445 target
nmap --script=ssh-auth-methods -p 22 target
nmap --script=mysql-info -p 3306 target
```

### Workflow: Bug Bounty

```bash
# 1. Subdomain → IP
nmap -sn -Pn subdomain.target.com

# 2. Quick port scan
nmap -sS -T4 --top-ports 1000 IP

# 3. Full port scan (background)
nmap -sS -p- -T4 --min-rate 1000 -oA full_scan IP

# 4. Service detection on open ports
nmap -sV -sC -p OPEN_PORTS IP

# 5. Web-specific
nmap --script=http-enum,http-title,http-headers -p 80,443,8080,8443 IP

# 6. SSL check
nmap --script=ssl-enum-ciphers -p 443 IP
```

---

## 9. Integration dengan Tools Lain

```bash
# Nmap → Nuclei
nmap -p- -oX scan.xml target
nuclei -l scan.xml

# Nmap → SQLMap
nmap --script=http-enum -p 80 target | grep "/*.php" > urls.txt
sqlmap -m urls.txt --batch

# Nmap → Gobuster
nmap -p 80,443 target | grep open > ports.txt
gobuster dir -u http://target -w wordlist.txt

# Nmap → Metasploit
nmap -sV -sC --script=vuln target
# Import ke msfconsole
```

---

## 10. Common Mistakes

| Mistalah | Fix |
|----------|-----|
| Scan tanpa `-Pn` di host yang block ping | Tambah `-Pn` |
| Lupa cek UDP | Tambah `-sU --top-ports 20` |
| Scan port 65535 di semua host | Pakai host discovery dulu |
| Lupa save output | Selalu pakai `-oA` |
| aggressive scan di production | Pakai `-T2` atau `-T3` |
| lupa cek firewall | Pakai `-sA` untuk map rules |

---

## Verdict Standard

| Verdict | Kapan |
|---------|-------|
| **SOLID** | Bisa reproduce scan, ada evidence |
| **PLAUSIBLE** | Konsisten tapi belum confirmed |
| **UNVERIFIABLE** | Butuh akses tambahan |

*End skill — gas lanjut, jangan mandek ya tod.*
