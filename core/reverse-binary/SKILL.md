---
name: reverse-binary
description: |
  Binary reverse engineering dalam Bahasa Indonesia. Gunakan saat user mau analisis file executable (exe/dll/elf/so/macho), decompile program, cari password dalam binary, patch binary, atau memahami cara kerja sebuah program tertutup.
  Kata kunci: reverse binary, reverse engineering, decompile, exe, dll, elf, so file, macho, analyse binary, cari password, bypass, patch binary, disassemble, obfuscation, unpacking, IDA, ghidra, radare2, woy buka exe, cari password di program, crack program, keygen, serial, unpack, reverse exe, analisis program tertutup.
---

# Reverse Binary — Binary Reverse Engineering

> **Disclaimer:** Skill ini untuk analisis binary yang lo miliki ya tod, terima izin untuk dianalisis, atau konteks edukasi (CTF, lab).

---

## Pendahuluan (Baca Dulu)

Reverse engineering binary = ngupas cara kerja program yang gak ada source code-nya. Lo bakal bedah file executable buat nemuin logic, algorithm, dan vulnerability-nya — SABAR, WOY, bedah binary itu kerjanya pelan-pelan, bukan kek silet.

**Intensity guide:**
- `INTENSITY 1-3`: Identifikasi & recon (file type, strings, headers)
- `INTENSITY 4-6`: Static analysis (decompilation, algorithm restore)
- `INTENSITY 7-9`: Dynamic analysis (debugging, tracing, patching)
- `INTENSITY 10`: Full runtime manipulation (hook, unpack obfuscation)

---

## APA YANG KITA ANALISIS

| File Type | Magic Bytes | Ekstensi |
|-----------|-------------|----------|
| Windows PE | MZ | .exe, .dll, .sys |
| Linux ELF | \x7fELF | (no ext), .so, .o |
| macOS Mach-O | feedface/feededfe | .app, .dylib, .so |
| Java | \xca\xfe\xba\xbe | .class, .jar |
| .NET | MZ+CLR metadata | .exe, .dll (managed) |
| Android DEX | dex\n035\0 | .dex |

---

## Workflow Step-by-Step

### Tahap 1 — Identifikasi & Recon

```bash
# 1. Cek tipe file
file target.exe
file target.elf
file whatever

# 2. Cek strings (kadang password langsung kelihatan)
strings target.exe | grep -i password
strings target.exe | grep -i key
strings target.exe | grep -i "http://"

# 3. Cek header (architecture, section)
readelf -h target.elf       # ELF
objdump -f target.exe       # PE
otool -h target.dylib       # Mach-O

# 4. Cek imports/exports (fungsi yang dipake)
nm -D target.elf | head
objdump -T target.so
```

**Analisis strings (penting untuk pemula):**
```bash
# Cari semua strings yang menarik
strings -n 8 target.exe

# Cari URL
strings target.exe | grep -E "https?://"

# Cari base64 / hex
strings target.exe | grep -E "^[A-Za-z0-9+/]{20,}={0,2}$"

# Cari flag pattern (CTF)
strings target.exe | grep -i flag
```

---

### Tahap 2 — Static Analysis (Analisis Statis)

> Tujuannya: Pahami alur program tanpa menjalankannya.

**2.1 Decompilation Tools**

| Tool | Kapan Pakai | Command |
|------|-------------|---------|
| **Ghidra** | FREE, Multi-platform | `ghidraAnalyzer` atau buka GUI |
| **radare2** | CLI, cepat | `r2 target.exe` |
| **objdump** | Quick disassembly | `objdump -d target.exe` |
| **IDA Pro** | Best-in-class, mahal | GUI |
| **retdec** | Free decompiler | `retdec-decompiler.py target.exe` |
| **angr** (symbolic exec) | Automate analysis | Python script |

**2.2 Ghidra Workflow (Free, REKOMENDASI untuk pemula)**

```bash
# Cara pakai Ghidra:
# 1. Open Project → Import file
# 2. Auto-Analysis (ok semua default)
# 3. Entry point → main() → decompiled code muncul
# 4. Cross Reference (Ctrl+Shift+F) → cari callers
```

**2.3 radare2 Workflow (CLI)**

```bash
r2 target.exe        # Masuk mode interaktif
aaa                  # Analyze all
afl                  # List all functions
s main               # Seek ke main
pdf                  # Print disassembly
V                    # Visual mode (panah kanan/kiri untuk nav)
izz                  # List strings
s sym.password       # Jump ke function password
```

**2.4 Analisis Algoritma**

Cari pattern umum dalam decompiled code:

```markdown
1. **Login check** → cari `strcmp`, `memcmp`, atau compare di decompile
2. **Serial/Keygen** → cari `sprintf`, `strlen`, aritmatika dengan input
3. **Crypto** → cari calls ke `AES_*`, `RSA_*`, `MD5_*`, custom XOR loop
4. **Obfuscation** → banyak junk code, string di-encode base64/hex
5. **Anti-debug** → `IsDebuggerPresent`, `ptrace`, timing checks
```

---

### Tahap 3 — Dynamic Analysis (Analisis Dinamis)

> Tujuannya: Verifikasi asumsi, trace runtime, temukan alur asli.

**3.1 Debugging**

```bash
# gdb (binary Linux)
gdb ./target.elf
b main                 # breakpoint di main
run                   # run
info registers        # lihat register
x/s $rax              # print string di register
ni / si               # step / step into
bt                    # backtrace

# lldb (macOS)
lldb ./target.app
breakpoint set --name main
run
```

**3.2 Patching (Modifikasi Binary)**

Skenario: Binary ngecheck serial, kalau gagal exit.

```bash
# 1. Cari string "Invalid license" di binary
strings target.exe | grep -i invalid

# 2. Cari offset-nya
# 3. Lihat disassembly di offset tersebut → asm jnz/jz
# 4. Patch instruction (ubah conditional jump)
# Contoh: `jnz 0x8048a00` → `jz 0x8048a00`

# Pakai radare2 untuk patch
r2 -w target.exe       # writable mode
s 0x08049810           # offset yang mau di-patch
wa jz 0x0804xxxx       # write new instruction
q                     # keluar & save

# Cek hasil
./target.exe           # Harusnya lolos check
```

---

### Tahap 4 — Anti-Analysis Handling

Binary yang di-obfuscate punya perlindungan:

| Protection | Cara Atasi |
|------------|-----------|
| **Packed** (UPX, Themida, VMProtect) | `upx -d target.exe` (kalau UPX); Ghidra auto; atau dump memory saat runtime |
| **String obfuscation** | Decode runtime; cari XOR loops; FlareVM decrypt_strings |
| **Anti-debug** | Patch `IsDebuggerPresent` return value; pakai `gdb set follow-fork-mode child`; scyllaHide plugin |
| **Obfuscated control flow** | Qiling/Unicorn emulation; symbolic execution (angr) |
| **Dead code / junk** | Skip, fokus di executed path |

**Unpack UPX:**

```bash
file target.exe        # "UPX compressed" → langsung unpack
upx -d target.exe -o unpacked.exe
file unpacked.exe      # Sekarang bukan UPX lagi
```

---

### Tahap 5 — Pelaporan

```markdown
## Analisis: [nama binary]

### Informasi Umum
- Tipe: PE/ELF/Mach-O
- Architecture: x86/x64/ARM
- Size: [size]
- Compiler: [deteksi kompiler]
- Protections: [UPX, ASLR, DEP, etc]

### Struktur Program
- Entry point: `0x...`
- Main function: `0x...`
- Key functions: [list nama debug symbols]

### Temuan
1. **Login check di** `0x...` — membandingkan input dengan string tersimpan
2. **Serial validation** menggunakan XOR cipher (key: `0x42`)
3. **Flag/Password** ditemukan di offset `0x...` (string tersimpan)

### Bukti
- Decompiled code snippet
- Command output
- Patch result (kalau di-patch)

### Kesimpulan
- Program [melakukan/berisi/tidak berisi] [temuan penting]
```

---

## Prohibited Actions (Serius, Jangan ISO Kepo)

1. **JANGAN** crack license/DRM komersial untuk distribusi ilegal
2. **JANGAN** analisis malware di environment yang tidak isolated
3. **JANGAN** eksekusi binary tidak dikenal di mesin utama
4. **JANGAN** distribute patched commercial software
5. **JANGAN** skip dynamic analysis kalau static tidak conclusive

---

## Tools untuk Pemula

| Situasi | Tool | Kenapa |
|---------|------|--------|
| Mau belajar decompile | **Ghidra** | Free, GUI, ada decompiler |
| CLI speed | **radare2** | Powerful, scriptable |
| Linux CTF challenge | **objdump + gdb** | Built-in, gak perlu install |
| Binary yang obfuscate | **angr** | Symbolic execution |
| .NET binary | **dnSpy** | Specialized for .NET |
| APK/DEX | **jadx, apktool** | (branchke mobile-android) |
| Quick strings | **strings, rabin2** | Instant recon |

---

## Tahap 6 — ARM Assembly Basics

> ARM = arsitektur utama mobile (Android/iOS). Lo HARUS ngerti dasar ARM buat analisis native .so.

### ARM vs x86

| Feature | x86/x64 | ARM |
|---------|---------|-----|
| Paradigm | CISC | RISC |
| Registers | EAX, EBX, ECX... (few) | R0-R15 (banyak) |
| Instructions | Complex, variable length | Simple, fixed length |
| Conditional | Flags register | Conditional execution per instruction |
| Memory access | Load/store anywhere | Load/store only (no mem-to-mem) |

### ARM Registers

```
R0-R3   = Argument/return values (caller-saved)
R4-R10  = General purpose (callee-saved)
R11     = Frame pointer (FP)
R12     = IP (Intra-procedure call)
R13     = SP (Stack Pointer)
R14     = LR (Link Register — return address)
R15     = PC (Program Counter)

CPSR    = Current Program Status Register (N, Z, C, V flags)
```

### Common ARM Instructions

```asm
; Data movement
MOV     R0, #0          ; R0 = 0
MOV     R1, R2          ; R1 = R2
LDR     R0, [R1]        ; R0 = *R1 (load from memory)
STR     R0, [R1]        ; *R1 = R0 (store to memory)
PUSH    {R4-R7}         ; push ke stack
POP     {R4-R7}         ; pop dari stack

; Arithmetic
ADD     R0, R1, R2      ; R0 = R1 + R2
SUB     R0, R1, R2      ; R0 = R1 - R2
MUL     R0, R1, R2      ; R0 = R1 * R2
AND     R0, R1, R2      ; R0 = R1 & R2
ORR     R0, R1, R2      ; R0 = R1 | R2
EOR     R0, R1, R2      ; R0 = R1 ^ R2 (XOR)

; Compare & branch
CMP     R0, R1          ; compare R0 vs R1 (set flags)
BEQ     target          ; branch if equal (Z=1)
BNE     target          ; branch if not equal
BLT     target          ; branch if less than
BGT     target          ; branch if greater than
B       target          ; unconditional branch
BL      target          ; branch with link (call function)
BX      LR              ; return (branch to LR)
```

### ARM Calling Convention

```
R0-R3   = Arguments (4 pertama)
R0      = Return value
R4-R11  = Callee-saved (harus dipertahankan)
SP      = Stack (16-byte aligned di ARMv7+)

Contoh function call:
MOV     R0, #1          ; arg1 = 1
MOV     R1, #2          ; arg2 = 2
BL      my_function     ; call my_function(1, 2)
; R0 sekarang berisi return value
```

### Reading ARM in Ghidra

```
// Decompiled C:
int check_password(char *input) {
    if (strlen(input) != 8) return 0;
    if (input[0] != 'p') return 0;
    // ...
    return 1;
}

// ARM assembly (sama):
check_password:
    PUSH    {LR}
    BL      strlen
    CMP     R0, #8
    BNE     fail
    LDRB    R0, [input]
    CMP     R0, #'p'
    BNE     fail
    MOV     R0, #1
    POP     {PC}
fail:
    MOV     R0, #0
    POP     {PC}
```

### Quick Reference

| Pattern | Artinya |
|---------|---------|
| `CMP R0, #0` / `BEQ` | if (R0 == 0) goto ... |
| `CMP R0, R1` / `BGT` | if (R0 > R1) goto ... |
| `BL function` | function call |
| `BX LR` | return |
| `LDR R0, [R1, #4]` | R0 = *(R1 + 4) |
| `STR R0, [R1]` | *R1 = R0 |
| `PUSH {R4, LR}` | save registers + return addr |
| `POP {R4, PC}` | restore + return |

---

## Tahap 7 — DEX File Format

> DEX = Dalvik Executable. Format binary untuk Android. Pahami struktur ini buat advanced APK analysis.

### DEX Structure

```
DEX File Header (0x00 - 0x70)
├── magic           (8 bytes)  → "dex\n035\0"
├── checksum        (4 bytes)  → Adler32
├── signature       (20 bytes) → SHA-1
├── file_size       (4 bytes)
├── header_size     (4 bytes)  → 0x70
├── endian_tag      (4 bytes)
├── link_size       (4 bytes)
├── link_off        (4 bytes)
├── map_off         (4 bytes)
├── string_ids_size (4 bytes)
├── string_ids_off  (4 bytes)
├── type_ids_size   (4 bytes)
├── type_ids_off    (4 bytes)
├── proto_ids_size  (4 bytes)
├── proto_ids_off   (4 bytes)
├── field_ids_size  (4 bytes)
├── field_ids_off   (4 bytes)
├── method_ids_size (4 bytes)
├── method_ids_off  (4 bytes)
├── class_defs_size (4 bytes)
├── class_defs_off  (4 bytes)
└── data_size       (4 bytes)
```

### String IDs Table

```
offset → string_data_item
string_data_item:
  uleb128 utf16_size
  byte[]  data (UTF-8 encoded)
  byte    null terminator
```

### Type IDs Table

```
type_id_item:
  uint descriptor_idx  → index ke string_ids
```

### Method IDs Table

```
method_id_item:
  ushort class_idx     → index ke type_ids
  ushort proto_idx     → index ke proto_ids
  ushort name_idx      → index ke string_ids
```

### Class Defs Table

```
class_def_item:
  uint  class_idx      → index ke type_ids
  uint  access_flags
  uint  superclass_idx → index ke type_ids
  uint  interfaces_off
  uint  source_file_idx → index ke string_ids
  uint  annotations_off
  uint  class_data_off  → pointer ke class_data_item
  uint  static_values_off

class_data_item:
  uleb128 static_fields_size
  uleb128 instance_fields_size
  uleb128 direct_methods_size
  uleb128 virtual_methods_size
  encoded_field[] static_fields
  encoded_field[] instance_fields
  encoded_method[] direct_methods
  encoded_method[] virtual_methods
```

### Parsing DEX

```bash
# dexdump (Android SDK)
dexdump -d classes.dex

# dex2jar → convert ke JAR
d2j-dex2jar app.apk -o output.jar

# jadx (recommended)
jadx -d output app.apk

# radare2
r2 classes.dex
iS           # list sections
iz           # list strings
ic           # list classes
```

### DEX Security Features

| Feature | Description |
|---------|-------------|
| CRC32 | Header integrity check |
| SHA-1 | File signature |
| Checksum | Detect tampering |
| Bytecode verification | Runtime validation |
| Access flags | Visibility modifiers |

### DEX Manipulation (Advanced)

```bash
# Decompile
jadx -d src app.apk

# Modify smali (in apktool output)
# Edit .smali files di smali/ directory

# Recompile
apktool b modified_apk/ -o new.apk

# Re-sign
apksigner sign --ks debug.keystore new.apk
```

---

## Tahap 8 — .NET Reverse Engineering

> .NET = managed runtime. Binary berisi IL (Intermediate Language), bukan native code. Tools berbeda dari native RE.

### Ciri .NET Binary

```bash
# Cek apakah .NET binary
file target.exe
# Output: PE32 executable (console) .NET assembly

# Cek di PE headers
# 0x00E0: COM Descriptor (CLR header)
# Magic: 0x424A5342 (BSJB)
```

### .NET Tools

| Tool | Fungsi |
|------|--------|
| **dnSpyEx** | Decompiler + Debugger + Editor (successor dnSpy) |
| **de4dot** | Deobfuscator (dot12, ConfuserEx, Babel) |
| **ILSpy** | Open-source decompiler |
| **Harmony** | Runtime patching library |
| **Cecil** | IL manipulation library |
| **dotPeek** | JetBrains decompiler |
| **X64dbg** | Debug .NET (with .NET plugin) |

### dnSpyEx Workflow

```
1. Buka dnSpyEx
2. File → Open → target.exe/dll
3. Browse namespace di panel kiri
4. Double-click method → decompiled C# code
5. Edit: Right-click method → Edit Method (C#)
6. Compile: Ctrl+Shift+S → Save modified assembly
```

### de4dot (Deobfuscation)

```bash
# Basic deobfuscation
de4dot target.exe -o clean.exe

# Scan mode (untuk detect obfuscator)
de4dot target.exe -r output_dir

# With specific options
de4dot.exe target.exe -p -ep-method-check -save

# Batch deobfuscation
de4dot.exe *.dll -o cleaned/
```

### Common .NET Obfuscators

| Obfuscator | Ciri | Deobfuscator |
|------------|------|--------------|
| dot12 | String encryption, proxy | de4dot (built-in) |
| ConfuserEx | Anti-tamper, VM | de4dot (partial) |
| Babel | String encryption | de4dot (built-in) |
| SmartAssembly | String encode | de4dot |
| .NET Reactor | Native AOT | de4dot (partial) |

### IL (Intermediate Language) Basics

```il
// C# code
int Add(int a, int b) { return a + b; }

// IL equivalent
.method private hidebysig instance int32 Add(int32 a, int32 b) cil managed
{
    ldarg.1      // load arg1 (a)
    ldarg.2      // load arg2 (b)
    add          // a + b
    ret          // return
}
```

### Common IL Instructions

| Instruction | Artinya |
|-------------|---------|
| `ldarg.N` | Load argument N |
| `ldloc.N` | Load local variable N |
| `stloc.N` | Store ke local variable N |
| `ldstr "str"` | Load string literal |
| `ldc.i4.N` | Load constant integer N |
| `call` | Call static method |
| `callvirt` | Call virtual method |
| `ret` | Return |
| `brfalse` | Branch if false |
| `brtrue` | Branch if true |
| `box` | Value type → reference type |
| `unbox` | Reference type → value type |
| `newobj` | Create new object |
| `ldfld` | Load field |
| `stfld` | Store field |

### .NET Assembly Structure

```
PE Headers
├── CLI Header (COM Descriptor)
│   ├── MetaData → string table, type definitions
│   ├── IL Code → compiled C#/VB.NET
│   └── Resources → embedded resources
├── Type Definitions
├── Method Bodies
└── Resources
```

### de4dot + dnSpy Workflow

```
1. Detect obfuscator: de4dot -r target.exe
2. Deobfuscate: de4dot target.exe -o clean.exe
3. Open in dnSpyEx
4. Browse decompiled code
5. Edit if needed → Save
```

### .NET vs Native RE

| Aspect | .NET | Native |
|--------|------|--------|
| Code | IL bytecode | Machine code |
| Decompile | Easy (dnSpy, ILSpy) | Hard (Ghidra, IDA) |
| Strings | Usually visible | Encrypted sometimes |
| Obfuscation | Common | Rare |
| Patching | IL edit + recompile | NOP/pattern patch |

---

## Tahap 9 — Advanced Unpacking

> Packer = enkripsi/obfuscasi binary. Unpacking = reverse proses packing untuk dapat original code.

### Types of Packers

| Packer | Level | Detection |
|--------|-------|-----------|
| UPX | Simple | `upx -t target.exe` |
| Themida/WinLicense | Advanced | Anti-debug, VM |
| VMProtect | Advanced | Virtual machine |
| Enigma Protector | Advanced | Multi-layer |
| Custom packer | Variable | Entropy analysis |

### Entropy Analysis

```bash
# Check entropy (tinggi = packed/encrypted)
# entropy.py
import sys
import math
from collections import Counter

def entropy(data):
    counter = Counter(data)
    length = len(data)
    return -sum((count/length) * math.log2(count/length) for count in counter.values())

with open(sys.argv[1], 'rb') as f:
    data = f.read()
print(f"Entropy: {entropy(data):.2f}")
# > 7.0 → likely packed
# < 5.0 → likely unpacked

# entropy_scatter.py
# Plot entropy distribution across binary
```

### UPX Unpacking

```bash
# Detect
upx -t target.exe

# Unpack
upx -d target.exe -o unpacked.exe

# If UPX patched (magic bytes changed)
# hexedit target.exe → fix UPX! magic
# Then: upx -d target.exe
```

### Manual Unpacking (Themida/VMProtect)

```bash
# Step 1: Run until OEP (Original Entry Point)
# Use x64dbg + ScyllaHide (anti-anti-debug)

# Step 2: Set breakpoint at:
# VirtualAlloc → log addresses
# VirtualProtect → find code section
# WriteProcessMemory → catch dump

# Step 3: Dump at OEP
# Scylla → IAT Autosearch → Fix IAT → Dump

# Step 4: Rebuild
# ImportREC → fix imports → rebuild
```

### ScyllaHide (Anti-Anti-Debug)

```
1. Download: https://github.com/x64dbg/ScyllaHide
2. Install plugin di x64dbg
3. Enable:
   - Anti-anti-debug
   - Anti-user-mode-hook
   - NtSetInformationThread
   - NtQueryInformationProcess
   - NtQuerySystemInformation
```

### Automated Unpacking Tools

| Tool | Fungsi |
|------|--------|
| **UPX** | Simple packer |
| **UniPack** | Multi-packer detection |
| **PEiD** | Packer detection |
| **Detect It Easy** | Packer/compiler detection |
| **Exeinfo PE** | Packer detection |
| **OllyDumpEx** | OllyDbg dump plugin |
| **Scylla** | IAT reconstruction |
| **ImportREC** | Import reconstruction |

### PEiD Detection

```bash
# PEiD signature scan
# Buka PEiD → Open → target.exe
# Detect packer/compiler
# Cari signature: "UPX", "Themida", "VMProtect"
```

---

## Tahap 10 — Binary Diffing

> Binary Diffing = bandingkan 2 versi binary untuk cari patch/update. Berguna untuk N-day analysis, vulnerability research.

### Tools

| Tool | Type | Usage |
|------|------|-------|
| **BinDiff** | IDA Pro plugin | Commercial, powerful |
| **Diaphora** | IDA Pro plugin | Open-source |
| **radiff2** | CLI (radare2) | Free, fast |
| **bindiff** | IDA standalone | Free alternative |
| ** BinDig** | Ghidra | Free |

### radiff2 (radare2)

```bash
# Function-level diff
radiff2 -s old.exe new.exe

# Binary diff (byte level)
radiff2 -p old.exe new.exe

# Code diff
radiff2 -d old.exe new.exe

# Hash comparison
radiff2 -s old.exe new.exe | head -20

# Visual diff
radiff2 -g old.exe new.exe
```

### Diaphora (IDA Pro)

```
1. Load old binary → IDA
2. Diaphora → Diff → Select new binary
3. Results:
   - Matched functions (identical/modified)
   - Unmatched functions (new/removed)
   - Patch locations
4. Export diff report
```

### BinDiff (IDA Pro)

```
1. Open old binary → IDA
2. BinDiff → Diff → New binary
3. Match algorithms:
   - MD index (geometric hashing)
   - Call graph matching
   - String references
4. Results table with similarity %
```

### N-Day Analysis Workflow

```
1. Get vulnerable version (e.g., OpenSSL 1.0.2u)
2. Get patched version (e.g., OpenSSL 1.0.2v)
3. BinDiff/Diaphora diff
4. Find added security checks
5. Identify vulnerability location
6. Write exploit for vulnerable version
7. Test against patched version
```

### Common Patch Patterns

| Pattern | Indikasi |
|---------|----------|
| Bounds check added | Buffer overflow fix |
| NULL check added | NULL pointer deref fix |
| Input validation added | Injection fix |
| Auth check added | Privilege escalation fix |
| Rate limit added | DoS fix |
| Sanitize function added | XSS/SQLi fix |

---

## Tahap 11 — Symbolic Execution (angr)

> angr = framework analysis dengan symbolic execution. Bisa solve constraint-based challenges otomatis.

### Install angr

```bash
pip install angr

# Full install
pip install angr[all]
```

### Basic angr Usage

```python
import angr

# Load binary
proj = angr.Project('./target', auto_load_libs=False)

# Create initial state
state = proj.factory.entry_state()

# Create simulation manager
simgr = proj.factory.simulation_manager(state)

# Explore for specific address
simgr.explore(find=0x401196, avoid=0x4011a0)

# Get solution
if simgr.found:
    found = simgr.found[0]
    print(found.posix.dumps(0))  # stdin
```

### angr Concepts

| Concept | Penjelasan |
|---------|------------|
| **State** | Snapshot program execution |
| **SimState** | Symbolic state + constraints |
| **SimulationManager** | Manage multiple states |
| **Explorer** | Find/avoid addresses |
| **Claripy** | Constraint solver |
| **Solver** | SAT/SMT solver |

### angr Solver Pattern

```python
import angr
import claripy

proj = angr.Project('./crackme', auto_load_libs=False)

# Create symbolic input
input_size = 64
input_data = claripy.BVS('input', input_size * 8)

state = proj.factory.blank_state(addr=proj.entry)
state.memory.store(0x10000000, input_data)

simgr = proj.factory.simulation_manager(state)

# Find password check success
simgr.explore(find=0x401196, avoid=0x4011a0)

if simgr.found:
    found = simgr.found[0]
    solver = found.solver
    # Constrain stdin to printable
    for i in range(input_size):
        byte = solver.eval(input_data.get_byte(i))
        if 0x20 <= byte <= 0x7e:
            print(chr(byte), end='')
        else:
            print(f'\\x{byte:02x}', end='')
```

### angr Script Templates

```python
# Template 1: Simple password check
import angr

proj = angr.Project('./target', auto_load_libs=False)
state = proj.factory.entry_state()
simgr = proj.factory.simulation_manager(state)
simgr.explore(find=0xADDR_SUCCESS, avoid=0xADDR_FAIL)
if simgr.found:
    print(simgr.found[0].posix.dumps(0))

# Template 2: With constraint
import angr
import claripy

proj = angr.Project('./target', auto_load_libs=False)
state = proj.factory.entry_state()
sym = claripy.BVS('flag', 8*32)
state.memory.store(0x100000, sym)

simgr = proj.factory.simulation_manager(state)
simgr.explore(find=0xADDR_SUCCESS)

if simgr.found:
    sol = simgr.found[0].solver.eval(sym, cast_to=bytes)
    print(sol)

# Template 3: Avoid crash paths
import angr

proj = angr.Project('./target', auto_load_libs=False)
state = proj.factory.entry_state()
simgr = proj.factory.simulation_manager(state)

avoid_addrs = [0xADDR_CRASH1, 0xADDR_CRASH2]
simgr.explore(find=0xADDR_SUCCESS, avoid=avoid_addrs)
```

### angr for CTF

```python
# Solve crackme with angr
import angr

def solve(target, find_addr, avoid_addr):
    proj = angr.Project(target, auto_load_libs=False)
    state = proj.factory.entry_state()
    simgr = proj.factory.simulation_manager(state)
    simgr.explore(find=find_addr, avoid=avoid_addr)
    
    if simgr.found:
        return simgr.found[0].posix.dumps(0)
    return None

# Usage
password = solve('./crackme', 0x401196, 0x4011a0)
if password:
    print(f"Password: {password}")
```

### angr Common Patterns

| Scenario | Pattern |
|----------|---------|
| Password check | `explore(find=success, avoid=fail)` |
| Buffer overflow | `explore(find=win, avoid=crash)` |
| Constraint solving | `BVS + memory.store + explore` |
| Symbolic execution | `blank_state + SymExpr` |
| Loop unrolling | angr handles automatically |
| Function call | `hook_function` |

### angr vs Manual RE

| Aspect | angr | Manual |
|--------|------|--------|
| Speed | Fast (automated) | Slow (manual) |
| Accuracy | High (if well-configured) | Variable |
| Complexity | High (learning curve) |
| Flexibility | Low (specific tasks) | High |
| Best for | Constraint solving, CTF | Full analysis |

---

## Resources & Next Steps

- **crackmes.one** — Legal crackme challenges (latihan!)
- **pwn.college** — Free online RE course
- **CTF challenge** — HackTheBox, TryHackMe
- **Lena151 RE course** — Classic for beginners
- **ARM docs**: https://developer.arm.com/documentation/
- **DEX format**: https://source.android.com/docs/core/runtime/dex-format
- **angr docs**: https://docs.angr.io/
- **dnSpy**: https://github.com/dnSpyEx/dnSpy
- **de4dot**: https://github.com/de4dot/de4dot
- **Diaphora**: https://github.com/joxeankoret/diaphora
- **Day 1 RE**: `strings` + `file` + **Ghidra** = 70% temuan

Kalau lo baru mulai ya jink, saran gw — jangan sok-sokan dari yang susah:
1. Install Ghidra (free)
2. Bikin program sederhana sendiri (hello world dengan password check)
3. Compile → decompile → cari password-nya

Ini cara terbaik buat belajar, gak usah nanya mulu. Praktek, baru nanya.

---

## See Also (Module Terkait)

| Jika Task Lo... | Module Lain yang Relevan |
|-----------------|-------------------------|
| .NET assembly | `core/reverse-binary/SKILL.md` — .NET RE section |
| Network calls in binary | `core/network-recon/SKILL.md` — Port scan |
| Malware sample | `core/malware-analysis/SKILL.md` — Malware analysis |
| Exploit development | `core/exploit-dev/SKILL.md` — Exploit dev |
| Encrypted strings | `core/crypto/SKILL.md` — Crypto analysis |