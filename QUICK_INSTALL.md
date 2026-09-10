# 0xNxx-skill — Quick Install

## One-Line Install

### Windows (PowerShell)
```powershell
iex (iwr -Uri "https://raw.githubusercontent.com/bengt-skill/0xNxx-skill/main/scripts/oneclick-install.ps1").Content
```

### Linux / macOS / Termux
```bash
curl -sSL https://raw.githubusercontent.com/bengt-skill/0xNxx-skill/main/scripts/oneclick-install.sh | bash
```

### Manual Install
```bash
git clone https://github.com/bengt-skill/0xNxx-skill.git
# Then follow agent-specific instructions below
```

---

## Agent-Specific Quick Install

### OpenCode
```powershell
# Windows
iex (iwr -Uri "https://raw.githubusercontent.com/bengt-skill/0xNxx-skill/main/scripts/oneclick-install.ps1").Content

# Linux
curl -sSL https://raw.githubusercontent.com/bengt-skill/0xNxx-skill/main/scripts/oneclick-install.sh | bash
```

### Claude Code
```bash
# Clone to Claude skills directory
git clone https://github.com/bengt-skill/0xNxx-skill.git ~/.claude/skills/0xNxx-skill
```

### Cursor / Windsurf / Cline
```bash
# Clone to project
git clone https://github.com/bengt-skill/0xNxx-skill.git .skills/0xNxx-skill

# Copy rules file
cp .skills/0xNxx-skill/configs/cursor/.cursorrules ./
```

### Universal (All Agents)
```bash
# Clone anywhere
git clone https://github.com/bengt-skill/0xNxx-skill.git

# Copy to your project
cp -r 0xNxx-skill/core/ /path/to/project/core/
cp 0xNxx-skill/configs/universal/AGENTS.md /path/to/project/
```

---

## After Installation

1. Open your AI agent
2. Type tasks in Bahasa Indonesia
3. Agent will auto-route to correct module

### Example Tasks
```
"Scan website https://example.com for vulnerabilities"
"Analyze this binary and find the password"
"Bypass SSL pinning on this APK"
"Enumerate subdomains for target.com"
```

### Mode Selection
```
"Mode beginner: explain step by step"
"Mode professional: compact report"
"Mode CTF: solve fast"
```

---

## Content Protection

Skill files are protected and cannot be easily read by users:

- **SKILL.md files** — Protected by license
- **Trust manifest** — SHA-256 integrity verification
- **Verify script** — Check for tampering

### Verify Installation
```bash
# Windows
powershell -ExecutionPolicy Bypass -File scripts/verify-skill.ps1

# Linux
bash scripts/verify-skill.sh
```

---

## Troubleshooting

### "Command not found"
- Ensure you have internet connection
- Try manual install with `git clone`

### "Permission denied"
- Linux/macOS: Run with `sudo` or fix permissions
- Windows: Run PowerShell as Administrator

### "Agent not detecting skill"
- Check install path matches agent requirements
- Restart the AI agent
- Verify files exist in correct location

---

## Uninstall

### Windows
```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.config\opencode\skills\0xNxx-skill"
```

### Linux/macOS
```bash
rm -rf ~/.config/opencode/skills/0xNxx-skill
```
