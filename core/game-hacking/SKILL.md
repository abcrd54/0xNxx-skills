---
name: game-hacking
description: |
  Game hacking dalam Bahasa Indonesia. Gunakan saat user mau reverse engineering game, bypass anti-cheat, atau modify game behavior untuk authorized testing/CTF.
  kata kunci: game hacking, anti-cheat bypass, cheat engine, game modding, memory hacking, game reverse engineering, aimbot, wallhack, esp, game debug, unity hacking, unreal engine hacking.
---

# Game Hacking — Reverse Engineering & Memory Manipulation

> **Disclaimer:** Skill ini HANYA untuk game yang lo MILIKI, CTF challenges, atau authorized testing. Cheating di online game = bannable offense. JANGAN nekat.

---

## Pendahuluan

Game hacking = reverse engineer game, manipulate memory, bypass anti-cheat. Berguna untuk CTF, security research, dan authorized testing.

**Intensity guide:**
- `INTENSITY 1-3`: Recon (game analysis, memory scanning)
- `INTENSITY 4-6`: Basic hacking (memory edit, DLL injection)
- `INTENSITY 7-9`: Advanced (anti-cheat bypass, kernel driver)
- `INTENSITY 10`: Expert (custom engine hacking, kernel-level)

---

## Tahap 1 — Reconnaissance

> Tujuan: Kenali game engine, anti-cheat, dan protection.

### Game Analysis

```bash
# Check game executable
file game.exe
# Check for .NET: look for CLR header
# Check for Unity: look for UnityPlayer.dll
# Check for Unreal: look for UnrealEngine

# Check strings
strings game.exe | grep -i "steam\|easyanticheat\|battleye\|vanguard"
strings game.exe | grep -i "unity\|unreal\|godot\|cryengine"

# Check DLLs
dumpbin /dependents game.exe

# Check protection
# - VMProtect
# - Themida
# - Enigma Protector
# - Denuvo
```

### Anti-Cheat Detection

| Anti-Cheat | Type | Difficulty |
|------------|------|------------|
| **EasyAntiCheat (EAC)** | User-mode + Kernel | Medium |
| **BattlEye (BE)** | Kernel driver | High |
| **Vanguard (Riot)** | Kernel driver | High |
| **nProtect GameGuard** | Kernel driver | Medium |
| **XIGNCODE3** | Kernel driver | High |
| **EQU8** | User-mode | Medium |
| **Warden (Blizzard)** | User-mode | Medium |

### Engine Detection

| Engine | Ciri | Tools |
|--------|------|-------|
| **Unity** | Mono, Il2Cpp | dnSpy, Il2CppDumper |
| **Unreal** | UObject, AActor | UE4SS, UAssetGUI |
| **Godot** | GDScript, PCK | gdsdecomp |
| **CryEngine** | Lua, Flowgraph | CryEngine SDK |
| **Source Engine** | VGUI, ConVars | Source SDK |

---

## Tahap 2 — Memory Hacking

> Memory = target utama game hacking. Edit memory = edit game state.

### Cheat Engine

```
1. Attach ke process game
2. Scan value (health, ammo, etc.)
3. Change value di game
4. Rescan (narrow down)
5. Terus sampe ketemu address
6. Edit value
```

### Memory Scan Patterns

```python
# Scan for health
health_pattern = "?? ?? ?? ?? 7F 00 00 00"  # health = 127

# Scan for ammo
ammo_pattern = "?? ?? ?? ?? 63 00 00 00"  # ammo = 99

# Scan for base address
base_pattern = "48 8B 05 ?? ?? ?? ?? 48 85 C0 74 ?? 48 8B"
```

### Pointer Chains

```python
# Static pointer to dynamic memory
base = game.exe + 0x123456  # static address
ptr1 = read_memory(base)      # first pointer
ptr2 = read_memory(ptr1 + 0x10)  # second pointer
health_addr = ptr2 + 0x20     # final address
```

---

## Tahap 3 — DLL Injection

> Inject custom code ke game process.

### Classic DLL Injection

```cpp
// 1. Get process ID
DWORD pid = GetProcessIdByName("game.exe");

// 2. Open process
HANDLE hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);

// 3. Allocate memory
LPVOID remoteBuf = VirtualAllocEx(hProcess, NULL, strlen(dllPath), MEM_COMMIT, PAGE_READWRITE);

// 4. Write DLL path
WriteProcessMemory(hProcess, remoteBuf, dllPath, strlen(dllPath), NULL);

// 5. Create remote thread
CreateRemoteThread(hProcess, NULL, 0, (LPTHREAD_START_ROUTINE)GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA"), remoteBuf, 0, NULL);
```

### Manual Mapping

```cpp
// Manual map DLL (bypass load library detection)
// 1. Read DLL file
// 2. Map sections manually
// 3. Resolve imports
// 4. Call DllMain
```

---

## Tahap 4 — Aimbot

> Auto-aim ke target.

### Aimbot Logic

```cpp
// Get target position
Vector3 targetPos = GetTargetPosition(player);

// Get local player position
Vector3 localPos = GetLocalPlayerPosition();

// Calculate angle
Vector3 delta = targetPos - localPos;
float yaw = atan2(delta.y, delta.x) * 180.0 / PI;
float pitch = -asin(delta.z / sqrt(delta.x*delta.x + delta.y*delta.y)) * 180.0 / PI;

// Apply to view angles
SetViewAngles(pitch, yaw, 0);
```

### Aimbot Features

| Feature | Description |
|---------|-------------|
| **FOV** | Field of view filter |
| **Smoothing** | Human-like movement |
| **Bone selection** | Head, chest, etc. |
| **Prediction** | Leading target |
| **Silent aim** | Server-side aim |

---

## Tahap 5 — Wallhack / ESP

> See players through walls.

### ESP (Extra Sensory Perception)

```cpp
// Get all players
for (auto& player : GetPlayers()) {
    // Get screen position
    Vector2 screenPos = WorldToScreen(player.position);
    
    // Draw box
    DrawBox(screenPos.x - 10, screenPos.y - 10, 20, 20, RED);
    
    // Draw health bar
    DrawHealthBar(screenPos.x - 15, screenPos.y, player.health);
    
    // Draw name
    DrawText(screenPos.x, screenPos.y - 20, player.name);
}
```

### Wallhack

```cpp
// Change material properties
// Method 1: Disable Z-buffer
// Method 2: Change material color
// Method 3: Remove walls via shader
```

---

## Tahap 6 — Anti-Cheat Bypass

> Bypass detection systems.

### EAC Bypass

```cpp
// Method 1: Driver vulnerability
// Load vulnerable driver, exploit to unload EAC

// Method 2: User-mode patch
// Patch EAC hooks

// Method 3: Process hollowing
// Replace EAC process with clean process
```

### BattlEye Bypass

```cpp
// Method 1: Driver vulnerability
// Exploit BE driver to get kernel access

// Method 2: Direct syscall
// Bypass user-mode hooks

// Method 3: Manual mapping
// Map payload without using LoadLibrary
```

### Vanguard Bypass

```cpp
// Vanguard runs at kernel level
// Bypass options:
// 1. Boot before Vanguard
// 2. Driver vulnerability
// 3. Disable Vanguard (requires admin)
```

---

## Tahap 7 — Unity Hacking

> Unity = game engine populer. Hack via Mono or Il2Cpp.

### Mono Hacking

```bash
# 1. Extract assembly
# Game/Managed/Assembly-CSharp.dll

# 2. Decompile with dnSpy
dnSpy.exe Assembly-CSharp.dll

# 3. Find game classes
# Player, Enemy, GameManager, etc.

# 4. Patch with Harmony
Harmony.PatchAll();
```

### Il2Cpp Hacking

```bash
# 1. Dump IL2CPP metadata
Il2CppDumper.exe Game_Data/il2cpp_data/Metadata.dat

# 2. Analyze with Ghidra
# Load dumped files

# 3. Find game functions
# Use metadata to find function offsets
```

### Unity Memory Hacking

```python
# Find GameObject
game_object = scan_for_type("Player")

# Find component
transform = get_component(game_object, "Transform")

# Read position
position = read_vector3(transform + 0x38)
```

---

## Tahap 8 — Unreal Engine Hacking

> Unreal = AAA game engine. Hack via UObject system.

### UObject Dumper

```bash
# 1. Dump UE4 classes
UAssetGUI.exe Game.pak

# 2. Find classes
# APlayerController, ACharacter, etc.

# 3. Find properties
# Health, Ammo, etc.
```

### UE4 Memory Hacking

```python
# Find GWorld
gw = read_memory(game.exe + GWorld_offset)

# Get persistent level
level = read_memory(gw + 0x30)

# Get actors
actors = read_array(level + 0x98)
```

---

## Tools Cheat Sheet

| Tool | Fungsi |
|------|--------|
| **Cheat Engine** | Memory scanner/editor |
| **dnSpy** | .NET decompiler |
| **Il2CppDumper** | Unity IL2Cpp dump |
| **UAssetGUI** | Unreal asset editor |
| **x64dbg** | Debugger |
| **IDA Pro** | Disassembler |
| **Ghidra** | Decompiler |
| **Harmony** | .NET runtime patching |

---

## See Also (Module Terkait)

| Jika Task Lo... | Module Lain yang Relevan |
|-----------------|-------------------------|
| Game binary analysis | `core/reverse-binary/SKILL.md` — Binary RE |
| Anti-cheat driver | `core/edr-bypass/SKILL.md` — EDR bypass |
| DLL injection | `core/malware-dev/SKILL.md` — Malware dev |
| Memory forensics | `core/forensics/SKILL.md` — Forensics |
| Game networking | `core/network-recon/SKILL.md` — Network |
| Encryption in games | `core/crypto/SKILL.md` — Crypto |

---

## Resources

- **Cheat Engine**: https://cheatengine.org/
- **Guided Hacking**: https://guidedhacking.com/
- **UnknownCheats**: https://www.unknowncheats.me/
- **Unity + dnSpy**: https://github.com/dnSpy/dnSpy
- **Il2CppDumper**: https://github.com/Perfare/Il2CppDumper
- **UE4SS**: https://github.com/trumank/ue4ss
