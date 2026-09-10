---
name: 0xNxx-skill
description: |
  0xNxx-skill — Protected cybersecurity skill package. Auto-routes tasks to correct module.
  Usage: Agent loads skill-data.bin and routes based on task keywords.
---

# 0xNxx-skill — Protected Skill Router

## How to Use

This skill package is protected. All skill content is encoded in `skill-data.bin`.

### For AI Agents

1. Load `skill-data.bin` using the loader script
2. Route task to correct module based on keywords
3. Execute workflow from loaded skill content

### Loader Commands

```powershell
# List all modules
.\scripts\skill-loader.ps1 -List

# Load specific module
.\scripts\skill-loader.ps1 -Module "pentest-web"

# Interactive mode
.\scripts\skill-loader.ps1 -Interactive

# Route task automatically
.\scripts\skill-loader.ps1 -Task "scan website for vulnerabilities"
```

### Keyword Routing

| Keywords | Module |
|----------|--------|
| sql, sqli, xss, ssrf, ssti, idor, jwt, web, website, burp | pentest-web |
| binary, reverse, decompile, ghidra, radare | reverse-binary |
| apk, android, frida, ssl pinning | mobile-android |
| ipa, ios, keychain | mobile-ios |
| malware, virus, yara, rat | malware-analysis |
| nmap, port, scan, subdomain, recon | network-recon |
| exploit, pwn, buffer overflow, rop, privesc | exploit-dev |
| crypto, encrypt, decrypt, hash, rsa, xor | crypto |
| forensic, dfir, pcap, memory dump, stego | forensics |
| wifi, wpa, handshake | wifi-pentest |
| active directory, kerberos, dcsync, domain | active-directory |
| docker, kubernetes, container | container-escape |
| mitm, arp spoof, dns spoof | mitm-network |
| wordpress, wp | wordpress-exploit |
| edr, antivirus, bypass | edr-bypass |
| malware dev, implant, backdoor, shellcode | malware-dev |
| game, cheat, aimbot | game-hacking |
| red team, c2, command and control | redteam-c2 |
| breach, kill chain, attack chain | breach-workflows |

## Module List

| Module | Description |
|--------|-------------|
| pentest-web | Web application security testing |
| reverse-binary | Binary reverse engineering |
| mobile-android | Android security testing |
| mobile-ios | iOS security testing |
| malware-analysis | Malware analysis |
| network-recon | Network reconnaissance |
| exploit-dev | Exploit development |
| crypto | Cryptography |
| forensics | Digital forensics |
| wifi-pentest | WiFi security testing |
| active-directory | Active Directory attacks |
| container-escape | Docker/Kubernetes escape |
| mitm-network | Man-in-the-middle attacks |
| wordpress-exploit | WordPress exploitation |
| edr-bypass | EDR/AV evasion |
| malware-dev | Malware development |
| game-hacking | Game security research |
| redteam-c2 | Red team operations |
| breach-workflows | Full attack chains |

## Safety

- **Disclaimer:** Only for authorized testing
- **Content Protected:** Cannot be read manually
- **AI Access:** Agents can decode and use skill content
