---
name: network-recon
description: |
  Network reconnaissance dan penetration testing infrastruktur dalam Bahasa Indonesia. Gunakan saat user mau scan port, enum services, subdomain enumeration, OS detection, kerentanan jaringan, atau eksplorasi attack surface target.
  Kata kunci: nmap, scan port, port scan, network scan, subdomain, recon, attack surface, masscan, ping sweep, service enum, OS detection, open port, vulnerability scan, woy scan ip, cek port terbuka, subnet scan, osint target, tembus jaringan, cek wifi tetangga (edukasi).
---

# Network Recon � Network Reconnaissance & Enumeration

> **Disclaimer:** Skill ini untuk network yang lo miliki atau punya izin untuk test ya jink. Broad internet scanning tanpa izin adalah ilegal.

---

## Pendahuluan

Network reconnaissance = fase pertama pentest. Gak bisa langsung iseng-iseng gedor, pahami ini dulu satu-satu:
1. **Find live hosts** � host mana yang hidup di target network
2. **Find open ports** � service apa yang jalan
3. **Find services & versions** � untuk mapping ke vulnerability
4. **Attack surface mapping** � pintu mana yang bisa dimasukin

**Intensity guide:**
- `INTENSITY 1-3`: Passive (DNS, certificates, search engine)
- `INTENSITY 4-6`: Active recon (nmap scan ringan)
- `INTENSITY 7-9`: Full scan (service version, OS detect)

---

## WORKFLOW STEP-BY-STEP

### Tahap 1 � Passive Recon (Tidak Sentuh Target)

> Tidak ada aktivitas yang bisa dideteksi target.

**1.1 Subdomain Enumeration (Passive)**

```bash
# Pakai certificate transparency
crt.sh:
# URL: https://crt.sh/?q=%25.target.com&output=json
curl -s "https://crt.sh/?q=%25.target.com&output=json" | jq '.[].name_value'

# Pakai passive tools
subfinder -d target.com -passive
amass enum -passive -d target.com
whoxy.com / securitytrails.com (API)
```

**1.2 DNS Records**
```bash
dig target.com ANY
dig target.com MX
dig target.com TXT
dig target.com NS
dig target.com SOA
dig target.com A

# Zone transfer (jarang berhasil, tapi worth mencoba)
dig @ns1.target.com target.com AXFR
```

**1.3 Search Engine Dorking**

```
Google: site:target.com
Google: site:target.com filetype:pdf
Google: site:target.com inurl:admin
Google: "target.com" admin
Google: inurl:target.com filetype:sql
```

**1.4 Wayback Machine**

```bash
# Archived URLs (kadang ada endpoint lama yang masih hidup)
curl -s "http://web.archive.org/cdx/search/cdx?url=*.target.com/*&output=txt&fl=original&collapse=urlkey"
```

---

### Tahap 2 � Active Recon (Dimulai di sini)

> Mulai sentuh target secara ringan.

**2.1 Ping Sweep / Host Discovery**

```bash
# ICMP ping sweep
nmap -sn 192.168.1.0/24

# TCP sweep (kalau ICMP diblok)
nmap -sT -p 80,443,22,53 --open 192.168.1.0/24

# ARP scan (local network)
nmap -PR -sn 192.168.1.0/24
arp-scan -l
```

**2.2 Port Scan (Nmap)**

```bash
# Basic port scan (top 1000)
nmap -T4 -p- target.com

# Fast scan (port umum)
nmap -F target.com

# Service detection (versi)
nmap -sV target.com

# All: service + version + OS
nmap -sV -sC -O target.com
```

**2.3 Port Scan � Detailed Approach**

```bash
# STEP 1: Find open ports (quick, random order)
nmap -p- --host-timeout 10m -oN allports.txt target.com

# STEP 2: Detailed scan only open ports
nmap -p $(cat allports.txt | grep -oP '\d+/open' | cut -d/ -f1 | tr '\n' ',') \
     -sV -sC -O -oN details.txt target.com
```

**Penjelasan flag Nmap:**

| Flag | Fungsi |
|------|--------|
| `-sS` | SYN scan (stealth, setengah-open) |
| `-sT` | TCP connect scan (full connect, lebih obvious) |
| `-sV` | Version detection (banner grabbing) |
| `-sC` | Default scripts (safe scripts) |
| `-O` | OS detection |
| `-p-` | Semua port (1-65535) |
| `-Pn` | Skip ping, langsung scan (untuk host yang block ICMP) |
| `-A` | Aggressive (sV + sC + O + traceroute) |
| `-T4` | Timing template (1-5, 4 = balanced aggressive) |
| `-oN/-oX/-oG` | Output format (normal/XML/grepable) |

---

### Tahap 3 � Service & Version Enumeration

```bash
# Service version scan
nmap -sV -p 80,443,22,3306 target.com

# Banner grabbing manual (untuk service non-standard)
nc -nv target.com 22
nc -nv target.com 3389
openssl s_client -connect target.com:443
```

**Enumeration per service:**

**Web (80/443/8080):**
```bash
nmap -sV -sC -p 80,443 target.com
# Lihat: Server header, Redirect, Technologies
```

**SSH (22):**
```bash
nmap -sV -p 22 target.com
# Lihat: SSH version ? cari known vuln
```

**Database (3306, 5432, 1433):**
```bash
nmap -sV -sC -p 3306 target.com
# Oracle, MySQL, MSSQL banners
```

**SMB (139/445):**
```bash
nmap -sV -sC -p 139,445 target.com
smbclient -L //target.com/
enum4linux -a target.com
```

**RDP (3389):**
```bash
nmap -sV -p 3389 target.com
```

---

### Tahap 4 � Vulnerability Scanner

```bash
# Nmap NSE scripts (dangerous ones)
nmap -p 22 --script ssh-vuln* target.com
nmap --script vuln target.com

# Nuclei
nuclei -u target.com -nt (template semua)
nuclei -l hosts.txt -t cves/

# OpenVAS / Qualys (enterprise)
```

**Nmap NSE scripts yang penting:**

| Script | Fungsi |
|--------|--------|
| `http-title` | Web app title |
| `http-headers` | Server headers |
| `http-methods` | Allowed methods |
| `http-enum` | Directory brute-force |
| `ssl-cert` | SSL cert info |
| `vuln` | Known vuln scan |
| `smb-check-vulns` | SMB vulnerabilities |
| `ftp-anon` | FTP anonymous access |

---

### Tahap 5 � Web Spec.

Kalau port web terbuka, lanjut ke pentest-web module.

---

### Tahap 6 � Pelaporan

```markdown
## Network Recon Report

### Target
- Domain: target.com
- IPs: 1.2.3.4, 5.6.7.8
- Scope: /24

### Live Hosts
| IP | Ports Open | Services | Notes |
|----|-----------|----------|-------|
| 1.2.3.4 | 22,80,443 | SSH, HTTP, HTTPS | Web server |
| 1.2.3.5 | 3306 | MySQL | DB server (mencurigakan) |

### Findings
1. Port 3306 (MySQL) exposed ke internet � risk tinggi
2. Port 22 SSH version 7.4 � outdated, known CVE
3. SMB anonymous access allowed � enumeration mungkin

### Recommendations
- [rekomendasi per temuan]
```

---

## Larangan (JANGAN BANDEL)

1. **JANGAN** scan range IP yang bukan milik lo ya tod
2. **JANGAN** aggressive scan tanpa izin (bisa dos)
3. **JANGAN** scan subnet yang luas tanpa scoping
4. **JANGAN** store hasil scan sensitif di tempat tidak aman
5. **JANGAN** skip rate limiting (T1 max untuk target production)

---

## TOOL CHEAT SHEET

| Tool | Fungsi |
|------|--------|
| nmap | Port/service/OS scan |
| masscan | Ultra-fast port scan (butuh root) |
| subfinder | Passive subdomain |
| amass | Subdomain + ASN intelligence |
| httpx | HTTP probe (live URL check) |
| nuclei | Vulnerability template scan |
| enum4linux | SMB/LDAP enumeration |
| smbmap | SMB share enumeration |
| ffuf | Web fuzzing (dirs, subdomains, params) |
| gobuster | Directory/subdomain brute-force |
| shcheck | Security headers check |
| dnsx | DNS tooling |

---

## RESOURCES & NEXT STEPS

- **Nmap Book**: https://nmap.org/book/
- **nuclei-templates**: https://github.com/projectdiscovery/nuclei-templates
- **Assetnote wordlists**: https://wordlists.assetnote.io/
- **Search** sobre informasi company: OTX, Shodan, Censys

**Langkah untuk pemula:**
1. Mulai dari **virtual lab** (VirtualBox + 2-3 VM)
2. Praktek di **HackTheBox** / **TryHackMe** (legal sandbox)
3. Baru belajar port scan di scope production yang lo pegang ya meq

---

## Sub-Modules � Deep Dives

Kalau task lo spesifik, langsung buka sub-module ini:

| Sub-Module | Trigger | Lokasi |
|------------|---------|--------|
| **Nmap** | Nmap full workflow, NSE scripts, evasion | `nmap/SKILL.md` |
| **AWS Postexploit** | Cloud privesc, IAM abuse, S3 exploit | `aws-postexploit/SKILL.md` |

---

## See Also (Module Terkait)

| Jika Task Lo... | Module Lain yang Relevan |
|-----------------|-------------------------|
| Service exploitation | `core/exploit-dev/SKILL.md` — Exploit dev |
| Active Directory | `core/active-directory/SKILL.md` — AD pentest |
| Traffic interception | `core/mitm-network/SKILL.md` — MITM |
| Cloud infrastructure | `core/network-recon/aws-postexploit/SKILL.md` — AWS |
| WiFi network | `core/wifi-pentest/SKILL.md` — WiFi pentest |