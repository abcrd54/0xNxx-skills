---
name: mobile-ios
description: |
  iOS aplikasi reverse engineering dan security testing dalam Bahasa Indonesia. Gunakan saat user mau analisis IPA, iOS security, keychain dump, SSL pinning bypass di iOS, Frida untuk iOS, atau memahami cara kerja aplikasi iOS.
  Kata kunci: ios reverse, ipa analysis, ipa reverse, keychain dump, ios security, ssl pinning ios, frida ios, jailbreak, class dump, objection, ios testing, mobile security ios, woy buka ipa, ipa mod, decrypt ipa, dump token, jailbreak check.
---

# Mobile iOS — iOS Reverse Engineering & Security Testing

> **Disclaimer:** Skill ini untuk IPA yang lo miliki ya tod, konteks edukasi, atau aplikasi yang lo kembangkan ya meq. Melepas DRM atau redistribute tidak akan dibantu.

---

## Pendahuluan

iOS reverse engineering tuh BEDA BANGET dari Android, jangan disamain:
1. **Tidak ada setara apktool** — IPA adalah folder ZIP berisi binary Mach-O
2. **Jailbreak diperlukan** untuk most dynamic testing (kecuali pakai simulator)
3. **Frida dan Objection** adalah tool utama

**Prerequisites khusus iOS:**
- macOS (recommended) + Xcode + iOS SDK
- Atau: macOS + Frida + iOS simulator
- Device jalibreak (untuk dynamic testing di real device)
- `class-dump`, `objection`, `frida`

---

## WORKFLOW STEP-BY-STEP

### Tahap 1 — IPA Extraction & Recon

```bash
# 1. Cek tipe file (harusnya Mach-O)
file Payload/YourApp.app/YourApp

# 2. Cek architecture
lipo -info Payload/YourApp.app/YourApp

# 3. Cek header binary
otool -L Payload/YourApp.app/YourApp    # linked libraries
otool -I Payload/YourApp.app/YourApp    # imported symbols

# 4. Pindah ke folder app
cd Payload/YourApp.app
```

**Dekompresi IPA:**
```bash
unzip YourApp.ipa -d ipa_out/         # standard
# Lalu: Payload/YourApp.app/ <- binary utama di sini
```

---

### Tahap 2 — Static Analysis (Class Dump + Decrypt)

```bash
# 1. Class dump (cari semua class & method)
class-dump -H YourApp.app/YourApp -o headers/

# 2. Lihat class yang menarik
ls headers/ | grep -i "login\|auth\|crypto\|secure"
grep -r "http\|api\|url" headers/ | head -20

# 3. Cek encryption (API non-encrypted binary ? cek Info.plist)
cat YourApp.app/Info.plist
# "App store" jangan sertakan di Info.plist
```

**Decrypt app (untuk app App Store):**
```bash
# Butuh device jailbreak + clutch/frida
clutch -d com.example.app      # decrypt ke host
# Atau frida: frida-ios-dump
```

---

### Tahap 3 — Dynamic Analysis (Frida + Objection)

**Cek apa saja yang bisa kita explore:**

```bash
# Objection (runtime exploration, bagus untuk pemula!)
pip install objection

# List gethooks, SSL pinning, etc di aplikasi
objection --gadget com.example.app explore
```

**Common Frida iOS tasks:**

```javascript
// hook iOS method & print arguments
ObjC.classes.LoginViewController['-didTapLogin:'].implementation = function(btn) {
    console.log("Login tapped!");
    // get text fields
    var mainView = this.view();
    // panggil original
    return this['-didTapLogin:'](btn);
};
```

```javascript
// Jadikan semua SSL cert valid
ObjC.classes.NSURLSessionDelegate['-URLSession:didReceiveChallenge:completionHandler:']
    .implementation = function(session, challenge, handler) {
        var args = ObjC.block('void (^)(int, NSDictionary *)');
        // bypass logic
        handler(0, {});  // accept semua
    };
```

**Keychain dump (device jailbreak):**
```bash
# keychain-dumper
keychain-dumper -e -k /tmp/keychain-dump.plist
```

---

### Tahap 4 — URL Scheme & Custom Handling

```bash
# Cek URL schemes di Info.plist (kadang ada info leak)
plutil -p YourApp.app/Info.plist | grep -i "CFBundleURLSchemes"

# Test URL scheme
xcrun simctl openurl booted "myapp://some/path?token=abc"
# Cari apa yang app lakukan dengan skema tersebut
```

---

### Tahap 5 — SSL Pinning Bypass (iOS)

```bash
# Universal: Frida script untuk bypass SSL pinning
# ios-ssl-bypass script (open source)
# Atau: Objection
objection --gadget com.example.app explore
(objection)> android sslpinning disable
(objection)> ios sslpinning disable
```

---

### Tahap 6 — Pelaporan

```markdown
## Analisis: [nama aplikasi iOS]

### Informasi Umum
- Bundle ID: [com.example.app]
- Version: [1.2.3]
- Binary Architecture: [arm64]
- Encryption Status: [Encrypted/Decrypted]

### Temuan
1. **Keychain** berisi token session yang bisa dipakai kembali
2. **SSL pinning** di bypass via Frida (tidak ada certificate shift)
3. **URL scheme** bisa menerima parameter tidak divalidasi
4. **Class `NetworkManager`** menyimpan API key dalam binary

### Eksploitasi (kalau ada)
- [contoh request berhasil]

### Remediation
- [rekomendasi]

### Bukti
- [command / script / output]
```

---

## Tahap 7 — Jailbreak iOS (Buat Security Testing)

> Framing WAJIB: jailbreak di sini cuma buat **analisis & testing di device yang lo pegang / berizin uji**. Jailbreak punya orang tanpa izin ? JANGAN, DASAR. Gak ada pembahasan "buka kunci iCloud"/"bebas bayar app" gitu-gitu.

**Kenapa butuh jailbreak buat testing:**
- Dynamic analysis (Frida, Objection) butuh akses yang di-lock di device stock.
- Keychain dump, SSL pinning bypass, app hooking ? butuh runtime yang gak lagi di-restrict.

**Jenis jailbreak (pahami dulu):**

| Tipe | Gambaran | Tool |
|------|----------|------|
| **Checkm8 boot-based** (A10–A11) | Exploit bootrom, butuh USB boot ulang tiap reboot | palera1n, checkra1n |
| **Semi-untethered** (A12+) | Re-jailbreak manual setelah reboot | unc0ver, Dopamine, palera1n |
| **Rootful vs Rootless** | Rootful = root penuh; rootless = sebagian file system (default, lebih aman) | `palera1n --rootless` / `--rootful` |

**Workflow (ringkas):**

```bash
# 1. Cek eligible device dulu — JANGAN asal ngecek device orang
#    A10-A11 (iPhone 7-8/X) ? palera1n / checkra1n (bootrom)
#    A12+ -> tergantung versi iOS (unc0ver / Dopamine)

# 2. macOS/Linux:
brew install palera1n           # atau pakai tools folder
palera1n --jailbreak            # bakal minta DFU pas proses

# 3. Setelah ok, install package manager (Cydia/Sileo) lalu install:
#    openssh, frida, appinst, ldid, debugserver

# 4. Verify koneksi Frida:
frida-ps -U                     # mesti nampak proses iOS
```

**Fokus testing, bukan hal lain:**
- Attach ke app target dengan Frida/Objection:
  ```bash
  objection --gadget com.target.app explore
  frida -U -f com.target.app -l /path/hook.js
  keychain-dumper -e -k /tmp/keychain.plist   # cek sensitive storage app lo
  ```
- Bandingkan behavior app di kondisi **stock vs jailbroken** ? cari tau apakah app punya jailbreak detection; kalau ada, itu finding (biasanya "Jailbreak detection bypassable" ? Medium).

**Restore / cleanup setelah testing:**
- Device sendiri: **Settings ? General ? Transfer or Reset ? Erase All Content** (full reset).
- Atau Finder/iTunes ? **Restore** untuk nge-wipe state jailbreak.

**Catatan:**
- Garansi bisa hangus; exploit bootrom (A10–A11) nempel di firmware. Konsekuensi ditanggung pemilik device yang berizin.

---

## PROHIBITED ACTIONS

1. **JANGAN** decrypt app store app tanpa izin
2. **JANGAN** bypass DRM/FairPlay
3. **JANGAN** redistribute hasil reverse
4. **JANGAN** collect data pengguna dari aplikasi yang lo analisis ya tod
5. **JANGAN** gunakan jailbreak tool untuk kejahatan

---

## TOOL CHEAT SHEET

| Tool | Fungsi | Command |
|------|--------|---------|
| class-dump | Extract class header | `class-dump -H app -o out/` |
| otool | Mach-O analysis | `otool -L app` |
| lipo | Architecture info | `lipo -info app` |
| plutil | Info.plist parser | `plutil -p Info.plist` |
| Frida | Dynamic instrumentation | `frida -U -f com.example.app` |
| Objection | Runtime exploration | `objection explore` |
| Clutch | iOS app decryption | `clutch -d <bundle-id>` |
| keychainer | Keychain access | `keychain-dumper` |

---

## RESOURCES & NEXT STEPS

- **OWASP Mobile Security Testing Guide** (iOS Section): https://mas.owasp.org/
- **s1rius/ios-reversed** — daftar reverse engineered apps
- **Securing iOS Apps** oleh OWASP
- **Frida iOS tutorial**: https://frida.re/

**Catatan untuk pemula:**
- Mulai dari **iOS Simulator** di macOS (gak perlu jailbreak) — jangan langsung pengen jailbreak device orang lain, DASAR.
- Coba dengan aplikasi yang lo buat sendiri ya jink
- Baru naik ke real device + jailbreak kalau sudah paham

---

## Sub-Modules — Deep Dives

| Sub-Module | Trigger | Lokasi |
|------------|---------|--------|
| **Keychain** | iOS keychain dump, certificate pinning, method swizzling | `keychain/SKILL.md` |