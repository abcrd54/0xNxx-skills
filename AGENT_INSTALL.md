# 0xNxx-skill — Agent Configuration

Skill ini support berbagai AI agents. Pilih agent lo dan ikuti instruksi install-nya.

## Supported Agents

| Agent | Config File | Install Location |
|-------|-------------|------------------|
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

---

## OpenCode

```bash
# Copy skill ke OpenCode
cp -r 0xNxx-skill ~/.config/opencode/skills/

# Atau clone langsung
git clone https://github.com/bengt-skill/0xNxx-skill.git ~/.config/opencode/skills/0xNxx-skill
```

## Claude Code

```bash
# Copy skill ke Claude
cp -r 0xNxx-skill ~/.claude/skills/

# Atau project-based
cp -r 0xNxx-skill /path/to/project/.claude/skills/
```

## Cursor

```bash
# Copy .cursorrules ke project root
cp configs/cursor/.cursorrules /path/to/project/

# Atau global rules
# Cursor Settings → Rules → Add .cursorrules
```

## Windsurf

```bash
# Copy .windsurfrules ke project root
cp configs/windsurf/.windsurfrules /path/to/project/
```

## Cline

```bash
# Copy .clinerules ke project root
cp configs/cline/.clinerules /path/to/project/
```

## Roo Code

```bash
# Copy rules ke Roo Code
cp -r configs/roo/.roo /path/to/project/
```

## Aider

```bash
# Copy config ke project root
cp configs/aider/.aider.conf.yml /path/to/project/

# Set skills directory
export AIDER_SKILLS_DIR=/path/to/0xNxx-skill/core
```

## Codex / Kiro / Hermes

```bash
# Copy AGENTS.md ke project root
cp configs/universal/AGENTS.md /path/to/project/
```

---

## Universal Usage

Semua agent bisa akses skill ini dengan cara yang sama:

1. Copy folder `core/` ke project lo
2. Agent akan otomatis baca SKILL.md di setiap folder
3. Ketik task dalam Bahasa Indonesia
4. Agent akan route ke module yang tepat

**Contoh usage:**
```
"Scan website https://example.com cari vulnerability"
"APK ini ada SSL pinning, bypass pakai Frida"
"Analisis binary ini, cari format input yang benar"
```
