---
name: 0xNxx-skill
description: |
  0xNxx-skill — Paket skill keamanan siber dalam Bahasa Indonesia. Ini adalah skill master yang me-routing ke core modules.
  调用: 0xNxx-skill router
---

# 0xNxx-skill Super Router

> Skill ini berisi routing utama untuk seluruh paket skill. Baca `../SKILL.md` untuk instruksi lengkap.

## Penggunaan

Ketik task dalam Bahasa Indonesia, AI akan otomatis:
1. Route ke module yang tepat
2. Set dial sesuai context
3. Jalankan workflow

## Module List — Core

| Module | Lokasi | Kapan |
|--------|--------|-------|
| Pentest Web | `core/pentest-web/SKILL.md` | Web security, SQLi, XSS |
| Reverse Binary | `core/reverse-binary/SKILL.md` | Binary RE, decompile |
| Mobile Android | `core/mobile-android/SKILL.md` | APK mod, Frida |
| Mobile iOS | `core/mobile-ios/SKILL.md` | iOS RE, Frida |
| Malware Analysis | `core/malware-analysis/SKILL.md` | Virus, RAT, malware |
| Network Recon | `core/network-recon/SKILL.md` | Nmap, port scan |
| Exploit Dev | `core/exploit-dev/SKILL.md` | Pwn, ROP, exploit |
| Crypto | `core/crypto/SKILL.md` | RSA, XOR, AES, hash crack |
| Forensics | `core/forensics/SKILL.md` | DFIR, memory, PCAP, stego |
| WiFi Pentest | `core/wifi-pentest/SKILL.md` | WPA2/WPA3, evil twin, handshake |
| Active Directory | `core/active-directory/SKILL.md` | Kerberos, DCSync, Golden Ticket, PtH |
| Container Escape | `core/container-escape/SKILL.md` | Docker/K8s breakout |
| MITM Network | `core/mitm-network/SKILL.md` | ARP spoof, DNS spoof, LLMNR |
| WordPress Exploit | `core/wordpress-exploit/SKILL.md` | WP2SHELL, WPScan, XML-RPC |
| EDR Bypass | `core/edr-bypass/SKILL.md` | EDR/AV evasion, AMSI, ETW |
| Malware Dev | `core/malware-dev/SKILL.md` | RAT, backdoor, loader, shellcode |
| Game Hacking | `core/game-hacking/SKILL.md` | Anti-cheat bypass, memory hack |
| Red Team / C2 | `core/redteam-c2/SKILL.md` | C2 infrastructure, lateral movement |
| Breach Workflows | `core/breach-workflows/SKILL.md` | Full kill chain, breach simulation |

## Module List — Sub-Modules

| Sub-Module | Lokasi | Kapan |
|------------|--------|-------|
| SQLi | `core/pentest-web/sqli/SKILL.md` | SQL injection scenarios |
| XSS | `core/pentest-web/xss/SKILL.md` | Cross-site scripting |
| SSRF | `core/pentest-web/ssrf/SKILL.md` | Server-side request forgery |
| SSTI | `core/pentest-web/ssti/SKILL.md` | Template injection |
| IDOR | `core/pentest-web/idor/SKILL.md` | Broken object authorization |
| API/JWT | `core/pentest-web/api-jwt/SKILL.md` | JWT, OAuth, API auth |
| SSL Pinning (Android) | `core/mobile-android/ssl-pinning/SKILL.md` | SSL bypass Android |
| Keychain (iOS) | `core/mobile-ios/keychain/SKILL.md` | iOS keychain dump, swizzle |
| Nmap | `core/network-recon/nmap/SKILL.md` | Nmap full workflow |
| AWS Postexploit | `core/network-recon/aws-postexploit/SKILL.md` | Cloud privesc |
| Linux Privesc | `core/exploit-dev/linux-privesc/SKILL.md` | SUID, sudo, kernel |
| Windows Privesc | `core/exploit-dev/windows-privesc/SKILL.md` | UAC, Potato, token |
| YARA | `core/malware-analysis/yara/SKILL.md` | YARA rules, malware hunting |

## Production Notes

- Selalu baca SKILL.md module target sebelum mulai
- Set `INTENSITY` di awal (default 5)
- Ikuti alur operasional 6 fase: SCOUT → ARM → STRIKE → ESCALATE → CONSOLIDATE → REPORT (detail di `../references/ops-killchain.md`)
- Kalau task match sub-module spesifik (contoh: "SQLi"), buka sub-module langsung
- Kalau task match umum, buka module utama dulu
- Klaim tanpa bukti = `UNVERIFIABLE`, bukan `SOLID`
- Simpan pengalaman di `memory/local/`
- Selalu test di lab / target berizin

## Mode

| Mode | INTENSITY | STEALTH | EDUCATION |
|------|-----------|---------|-----------|
| pemula | 3 | 1 | 10 |
| profesional | 7 | 7 | 3 |
| ctf | 10 | 1 | 5 |

**Cara pakai:** Sebut mode di awal, contoh: `"Mode: ctf, challenge ini"`
