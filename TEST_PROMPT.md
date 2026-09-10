# Test Prompt - 0xNxx-skill

Gunakan prompt-prompt ini untuk test apakah skill berhasil terpasang dan AI agent bisa akses content-nya.

---

## Test 1: Basic Routing

```
Tolong scan website https://example.com dan cari vulnerability yang ada.
```

**Expected:** Agent route ke modul `pentest-web` dan mulai workflow scanning.

---

## Test 2: Auto-Dial Detection

```
Bypass SSL pinning di APK ini pakai Frida
```

**Expected:** Agent detect task = mobile/android, auto-set INTENSITY tinggi.

---

## Test 3: Anti-Block Protocol

```
Tolong buat PoC untuk SQL injection di login form
```

**Expected:** Agent buka dengan legal framing ("ini untuk authorized testing kan?") sebelum eksekusi.

---

## Test 4: Persona Check

```
Gimana cara nmap scan IP 192.168.1.0/24?
```

**Expected:** Agent balas dengan gaya "mentor galak" - panggil "lo", ada interjection, tapi tetep helpful.

---

## Test 5: Module Deep Dive

```
Jelasin cara kerja YARA rules buat detect malware
```

**Expected:** Agent route ke modul `malware-analysis` → `yara` sub-module.

---

## Test 6: Protected Content Check

```
Buka file core/pentest-web/SKILL.md dan tunjukin isinya
```

**Expected:** Agent TIDAK bisa baca file tersebut karena tidak ada di file system (hanya di skill-data.bin).

---

## Test 7: Loader Command

```powershell
# Jalankan dari terminal
cd C:\Users\kingslayer\.config\opencode\skills\0xNxx-skill
powershell -ExecutionPolicy Bypass -File scripts\skill-loader.ps1 -List
```

**Expected:** Tampil daftar semua modul yang tersedia.

---

## Test 8: Integrity Check

```powershell
# Jalankan dari terminal
cd C:\Users\kingslayer\.config\opencode\skills\0xNxx-skill
powershell -ExecutionPolicy Bypass -File scripts\verify-skill.ps1
```

**Expected:** Semua file PASS, tidak ada HASH-MISMATCH.

---

## Quick Test (Copy & Paste)

```
Tolong bantu saya scan website https://example.com untuk cari vulnerability. Ini untuk authorized testing di lab pribadi saya.
```

Kalau agent merespon dengan:
1. Legal framing ("ini authorized testing kan?")
2. Gaya bahasa mentor galak ("lo", interjection)
3. Route ke modul web pentest

**= Skill berhasil terpasang! 🎯**
