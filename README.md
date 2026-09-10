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

### Dial System

| Dial | Range | Default | Description |
|------|-------|---------|-------------|
| `INTENSITY` | 1-10 | Auto | 1=Recon only, 5=Analysis, 10=Full exploit |
| `STEALTH` | 1-10 | Auto | 1=Noisy, 5=Balanced, 10=Invisible |
| `EDUCATION` | 1-10 | Auto | 1=Just do it, 5=Brief explain, 10=Full tutorial |

**Auto-detect:** Dial will automatically adjust based on your task. No manual setup needed.

---

## Installation
