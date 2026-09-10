# 0xNxx-skill

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS%20%7C%20Termux-orange)
![Agents](https://img.shields.io/badge/agents-10%2B-brightgreen)

Comprehensive cybersecurity skill package for AI agents, written in **Bahasa Indonesia**. Supports OpenCode, Claude Code, Cursor, Windsurf, Cline, Roo Code, Aider, Codex, Kiro, Hermes, and other AI coding assistants.

> **DISCLAIMER:** This skill package is ONLY for educational purposes, authorized security testing, CTF competitions, and testing systems you own or have written permission to test. Unauthorized access to computer systems is illegal and punishable by law.

---

## Features

- **19 Core Modules** — Complete coverage from web pentesting to red team operations
- **21 Sub-Modules** — Deep-dive specialized skill files
- **10+ Agent Support** — Works with all major AI coding assistants
- **Dial System** — `INTENSITY` / `STEALTH` / `EDUCATION` for behavior control
- **3 Built-in Modes** — Beginner, Professional, CTF
- **Memory System** — Persistent learning across sessions
- **Cross-platform** — Windows, Linux, macOS, Android (Termux)

---

## Module Overview

### Core Modules

| Module | Description | Key Tools |
|--------|-------------|-----------|
| **Pentest Web** | Web application security testing | SQLMap, Nuclei, FFUF, Burp Suite |
| **Reverse Binary** | Binary reverse engineering | Ghidra, radare2, IDA Pro, angr |
| **Mobile Android** | Android APK analysis & modification | apktool, jadx, Frida, Objection |
| **Mobile iOS** | iOS application analysis | Frida, class-dump, Objection |
| **Malware Analysis** | Malware analysis & detection | YARA, PE-sieve, CAPE |
| **Network Recon** | Network reconnaissance & scanning | Nmap, Masscan, Subfinder |
| **Exploit Development** | Exploit writing & development | pwntools, GDB, ROPgadget |
| **Cryptography** | Cryptanalysis & cipher cracking | hashcat, John the Ripper |
| **Forensics** | Digital forensics & incident response | Volatility, tshark, steghide |
| **WiFi Pentest** | Wireless network security testing | aircrack-ng, hostapd, wifite |
| **Active Directory** | AD security assessment | Impacket, Rubeus, Mimikatz |
| **Container Escape** | Docker/Kubernetes security | Docker, kubectl, nsenter |
| **MITM Network** | Man-in-the-middle attacks | bettercap, Responder, mitmproxy |
| **WordPress Exploit** | WordPress security testing | WPScan, wpscan, nikto |
| **EDR Bypass** | Endpoint detection evasion | ScyllaHide, SysWhispers |
| **Malware Development** | Red team implant development | Custom C2, shellcode loaders |
| **Game Hacking** | Game security research | Cheat Engine, dnSpy |
| **Red Team / C2** | Command & control infrastructure | Cobalt Strike, Sliver |
| **Breach Workflows** | Full attack chain execution | MITRE ATT&CK framework |

### Sub-Modules

| Sub-Module | Description |
|------------|-------------|
| **SQLi** | SQL injection techniques & scenarios |
| **XSS** | Cross-site scripting (DOM, reflected, stored) |
| **SSRF** | Server-side request forgery |
| **SSTI** | Server-side template injection |
| **IDOR** | Insecure direct object references |
| **API/JWT** | API security & JWT token analysis |
| **SSL Pinning** | Certificate pinning bypass (Android) |
| **Nmap** | Advanced port scanning |
| **AWS Postexploit** | AWS privilege escalation |
| **Linux Privesc** | Linux privilege escalation |
| **Windows Privesc** | Windows privilege escalation |
| **YARA** | YARA rule creation & malware hunting |
| **Keychain** | iOS keychain data extraction |

---

## Installation

### Quick Install (Recommended)

**Windows (PowerShell):**
```powershell
iex (iwr -Uri "https://raw.githubusercontent.com/bengt-skill/0xNxx-skill/main/scripts/oneclick-install.ps1").Content
```

**Linux / macOS / Termux:**
```bash
curl -sSL https://raw.githubusercontent.com/bengt-skill/0xNxx-skill/main/scripts/oneclick-install.sh | bash
```

### Manual Install

```bash
# Clone the repository
git clone https://github.com/bengt-skill/0xNxx-skill.git

# For OpenCode
cp -r 0xNxx-skill ~/.config/opencode/skills/

# For Claude Code
cp -r 0xNxx-skill ~/.claude/skills/

# For Cursor/Windsurf/Cline (project-based)
cp configs/cursor/.cursorrules /path/to/project/
cp -r core/ /path/to/project/core/

# Universal (all agents)
cp configs/universal/AGENTS.md /path/to/project/
cp -r core/ /path/to/project/core/
```

### Supported AI Agents

| Agent | Configuration | Location |
|-------|---------------|----------|
| **OpenCode** | `opencode.json` | `~/.config/opencode/skills/` |
| **Claude Code** | `.claude/settings.json` | `~/.claude/skills/` |
| **Cursor** | `.cursorrules` | Project root |
| **Windsurf** | `.windsurfrules` | Project root |
| **Cline** | `.clinerules` | Project root |
| **Roo Code** | `.roo/rules.md` | Project root |
| **Aider** | `.aider.conf.yml` | Project root |
| **Codex** | `AGENTS.md` | Project root |
| **Kiro** | `.kiro/steering/*.md` | `.kiro/steering/` |
| **Hermes** | `AGENTS.md` | Project root |

### Tool Installation (Optional)

```bash
# Windows (PowerShell as Administrator)
powershell -ExecutionPolicy Bypass -File scripts/install.ps1

# Linux / Kali
sudo bash scripts/install.sh

# Android Termux
bash scripts/install-termux.sh
```

---

## Usage

### Basic Usage

Type your task in Bahasa Indonesia to the AI agent:

```
"Scan website https://example.com for vulnerabilities"
"Bypass SSL pinning on this APK using Frida"
"Analyze this binary and find the correct input format"
"Nmap scan for IP range 192.168.1.0/24"
```

### Mode Selection

```
"Mode beginner: explain this scan step by step"
"Mode professional: get straight to the point, compact report"
"Mode CTF: solve this challenge as fast as possible"
```

| Mode | INTENSITY | STEALTH | EDUCATION | Use Case |
|------|-----------|---------|-----------|----------|
| `beginner` | 3 | 1 | 10 | Learning, need full explanations |
| `professional` | 7 | 7 | 3 | Experienced, need compact output |
| `ctf` | 10 | 1 | 5 | Competition, speed > stealth |

### Dial System

| Dial | Range | Default | Description |
|------|-------|---------|-------------|
| `INTENSITY` | 1-10 | 5 | 1=Recon only, 5=Analysis, 10=Full exploit |
| `STEALTH` | 1-10 | 3 | 1=Noisy, 5=Balanced, 10=Invisible |
| `EDUCATION` | 1-10 | 7 | 1=Just do it, 5=Brief explain, 10=Full tutorial |

---

## Directory Structure

```
0xNxx-skill/
├── SKILL.md                    # Main router + modes
├── README.md                   # This file
├── SECURITY.md                 # Security protocols
├── LICENSE                     # MIT License
├── AGENT_INSTALL.md            # Multi-agent install guide
├── opencode.json               # OpenCode configuration
├── trust-manifest.json         # File integrity manifest
├── core/
│   ├── pentest-web/            # Web application pentesting
│   │   ├── sqli/              # SQL injection
│   │   ├── xss/               # Cross-site scripting
│   │   ├── ssrf/              # Server-side request forgery
│   │   ├── ssti/              # Server-side template injection
│   │   ├── idor/              # Insecure direct object references
│   │   └── api-jwt/           # API/JWT abuse
│   ├── reverse-binary/         # Binary reverse engineering
│   ├── mobile-android/         # Android security testing
│   │   └── ssl-pinning/       # Certificate pinning bypass
│   ├── mobile-ios/             # iOS security testing
│   │   └── keychain/          # Keychain data extraction
│   ├── malware-analysis/       # Malware analysis
│   │   └── yara/              # YARA rule development
│   ├── network-recon/          # Network reconnaissance
│   │   ├── nmap/              # Advanced Nmap usage
│   │   └── aws-postexploit/   # AWS post-exploitation
│   ├── exploit-dev/            # Exploit development
│   │   ├── linux-privesc/     # Linux privilege escalation
│   │   └── windows-privesc/   # Windows privilege escalation
│   ├── crypto/                 # Cryptography & cryptanalysis
│   ├── forensics/              # Digital forensics
│   ├── wifi-pentest/           # Wireless security testing
│   ├── active-directory/       # Active Directory attacks
│   ├── container-escape/       # Docker/Kubernetes escape
│   ├── mitm-network/           # Man-in-the-middle attacks
│   ├── wordpress-exploit/      # WordPress exploitation
│   ├── edr-bypass/             # EDR/AV evasion
│   ├── malware-dev/            # Malware development
│   ├── game-hacking/           # Game security research
│   ├── redteam-c2/             # Red team operations
│   ├── breach-workflows/       # Full attack chains
│   └── _router/               # Internal routing
├── configs/                    # Agent configurations
│   ├── claude/
│   ├── cursor/
│   ├── windsurf/
│   ├── cline/
│   ├── roo/
│   ├── aider/
│   └── universal/
├── scripts/                    # Installation scripts
│   ├── install.ps1
│   ├── install.sh
│   ├── install-termux.sh
│   ├── update-manifest.ps1
│   └── verify-skill.ps1
├── references/                 # Playbooks & documentation
└── memory/                     # Session memory storage
```

---

## Learning Resources

| Platform | URL | Purpose |
|----------|-----|---------|
| TryHackMe | https://tryhackme.com | Interactive learning |
| pwn.college | https://pwn.college | RE & pwn courses |
| PortSwigger Academy | https://portswigger.net/web-security | Web security labs |
| picoCTF | https://picoctf.org | CTF for beginners |
| OWASP Mobile Security | https://mas.owasp.org | Mobile security guide |
| LiveOverflow | https://youtube.com/@LiveOverflow | RE & pwn tutorials |
| MITRE ATT&CK | https://attack.mitre.org | Adversary tactics |
| HackTricks | https://book.hacktricks.xyz | Security cheatsheets |

---

## Security

This skill package implements multiple security layers to prevent tampering and supply chain attacks.

### Verification

```bash
# After installation, verify file integrity
powershell -ExecutionPolicy Bypass -File scripts/verify-skill.ps1
```

### Security Features

- **Trust Manifest** — SHA-256 baseline for all files (`trust-manifest.json`)
- **Verification Script** — Automated integrity checking (`scripts/verify-skill.ps1`)
- **Runtime Guard** — AI agent protection against injection attacks
- **Guardrail Denylist** — Automatic blocking of dangerous commands

### Suspicious Indicators

If you encounter any of the following, do NOT use the skill:

- **Shadow features** — Undocumented capabilities
- **Excessive permissions** — Requests to read all files or exfiltrate data
- **Unknown dependencies** — References to unfamiliar packages
- **Typosquatting** — Similar-looking package names

### Reporting Issues

Report security vulnerabilities to the official issue tracker. Do not fork privately to fix security issues.

---

## Legal Disclaimer

This project does NOT facilitate illegal activities. Users are fully responsible for compliance with local and international laws. Only use this skill on systems you own or have written permission to test.

**Authorized use cases:**
- Security testing of your own systems
- Authorized penetration testing engagements
- CTF competitions and educational labs
- Security research in isolated environments

**Prohibited activities:**
- Unauthorized access to computer systems
- Data theft or destruction
- Distribution of malware
- Any activity violating applicable laws

---

## License

MIT License — Feel free to use, modify, and distribute with attribution.

---

## Contributing

Contributions are welcome. Please:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed description
4. Ensure all files pass integrity verification

---

## Changelog

### v2.0.0 (Current)
- Added 6 new modules: WordPress, EDR Bypass, Malware Dev, Game Hacking, Red Team/C2, Breach Workflows
- Multi-agent support (10+ AI assistants)
- Improved routing table with 70+ keywords
- Cross-module reference system
- Auto-pivot logic

### v1.0.0
- Initial release with 13 core modules
- 21 sub-modules
- Dial system implementation
- Memory system
