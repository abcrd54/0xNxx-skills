---
name: mobile-android
description: |
  Android APK reverse engineering, modding, dan security testing dalam Bahasa Indonesia. Gunakan saat user mau buka APK, mod apk, bypass SSL pinning, Frida hooking, root detection bypass, smali patch, atau reverse engineering aplikasi Android.
  Kata kunci: mod apk, apk mod, buka apk, recompile apk, frida, frida android, ssl pinning bypass, root detection bypass, smali, jadx, apktool, adb, android security, hook android, patch apk, decompile apk, android reverse, woy, buka apk berbayar, hapus iklan apk, buka kunci premium, bypass ssl, root check bypass, apk ijo, hapus ads, unlock apk.
---

# Mobile Android � APK Reverse Engineering & Modding

> **Disclaimer:** Skill ini untuk APK yang lo miliki ya jink, aplikasi yang lo kembangkan ya meq, atau konteks edukasi/CTF. Mod APK tanpa izin mungkin melanggar ToS aplikasi tersebut.

---

## Pendahuluan

Android APK analysis punya 2 tujuan utama:
1. **Security Testing** � cari vulnerability di aplikasi
2. **Modding** � ubah behavior aplikasi (bypass, unlock, patch)

Skill ini bakal nuntun lo dari awal sampai crimp (unpack ? analyze ? modify ? rebuild ? install) ya meq � FOKUS, jangan sampe skip step yang mana pun, ngerti dulu baru jalan.

**Intensity guide:**
- `INTENSITY 1-3`: Unggah & inspect (baca manifest, lihat struktur)
- `INTENSITY 4-6`: Static analysis (decompile Java + smali)
- `INTENSITY 7-9`: Mod & patching (smali edit, resource mod)
- `INTENSITY 10`: Dynamic runtime (Frida hook, SSL bypass, Xposed)

---

## Prerequisites

```bash
# Android SDK (minimal: adb)
# adb dari Android Platform Tools (https://developer.android.com/tools/releases/platform-tools)

# Java JDK 11+ (untuk apktool/jadx)
java -version

# Python + Frida (untuk dynamic analysis)
pip install frida frida-tools

# Install jadx
# https://github.com/skylot/jadx/releases

# Install apktool
# https://ibotpeaches.github.io/Apktool/install/

# Enabler USB debugging di device (Developer Options)
adb devices   # harus nampak device
```

---

## WORKFLOW STEP-BY-STEP

### Tahap 1 � Triage (Inspect APK)

```bash
# 1. Cek namespace & permissions
apktool d app.apk -o apktool_out    # unpack smali + resource

# 2. Baca AndroidManifest.xml
cat apktool_out/AndroidManifest.xml

# 3. Lihat package info
aapt dump badging app.apk | head -20
# Alternatif: pakai "apkanalyzer" dari BuildTools

# 4. Cek apakah ada native .so libraries
find apktool_out -name "*.so"

# 5. Cek aktivitas/services/receivers
grep -E "activity|service|receiver|provider" apktool_out/AndroidManifest.xml | head -30
```

**Yang dicari di manifest:**
- `android:exported="true"` ? komponen yang bisa dipanggil dari luar
- `android:permission` ? permission yang dibutuhkan
- `MainActivity` ? entry point aplikasi
- `INTERNET` permission ? kalau ada, aplikasi internet-aware

---

### Tahap 2 � Static Analysis (Baca Kode Java)

```bash
# 1. Decompile DEX ke Java (lebih readable)
jadx -d jadx_out app.apk

# 2. Baca kode Java yang penting (cari untuk pahami)
find jadx_out -name "MainActivity.java"
cat jadx_out/sources/com/example/app/MainActivity.java
```

**Target analisis yang common:**

| Kelas | Alasan |
|-------|--------|
| `LoginActivity` | Cari login logic, default creds |
| `MainActivity` | Entry point, cari flow utama |
| `*Api*`, `*Network*` | Endpoint, request auth |
| `*Crypto*`, `*Encode*` | Encryption logic |
| `Application` class | Init logic, key storage |
| `WebView` | WebView injection, JavaScript bridge |

---

### Tahap 3 � Modding (Patching APK)

> Multi-step, follow urutan dengan hati-hati di setiap langkah.

**3.1 Smali Patching � Root Detection Bypass**

Lokasi root detection biasa: kelas `Util`/`SecurityCheck`/`RootCheck`.

```smali
# Contoh smali di kelas RootCheck.smali
.method public static isRooted()Z
    .registers 2

    # Cari bagian yang return 0x1 (true) untuk rooted

    const/4 v0, 0x1    # <- patch ini jadi 0x0
    return v0
.end method
```

**3.2 Smali Patching � License Check Bypass**

```smali
# Cari kondisi yang menentukan licensed/pirated
# Contoh:
.method public isLicensed()Z
    const/4 v0, 0x0    # <- patch jadi 0x1 (jadi selalu licensed)
    return v0
.end method
```

**3.3 Smali Patching � Remove Ads**

```bash
# Cari ad SDK di manifest
grep -i "admob\|unityads\|facebook\|applovin" apktool_out/AndroidManifest.xml

# Atau cari kelas ad
find apktool_out -path "*adbanner*" -o -name "*AdManager*"
# Kemudian edit smali untuk no-op calls mereka
```

**3.4 Resource Modding � Ganti Icon/Splash/Text**

```bash
# Icon: ganti res/mipmap-*/ic_launcher.png
# Text: edit res/values/strings.xml
# Color: edit res/values/colors.xml
```

---

### Tahap 4 � Rebuild & Sign

```bash
# 1. Rebuild smali ke APK
apktool b apktool_out -o rebuilt.apk

# 2. SignAPK (apksigner dari BuildTools / zipalign+sign)
# Cara paling simple pakai debug key:
zipalign -v 4 rebuilt.apk aligned.apk
apksigner sign --ks ~/.android/debug.keystore \
    --ks-pass pass:android \
    --key-pass pass:android \
    aligned.apk

# 3. Install
adb install -r aligned.apk
```

**Catatan penting (jangan disepelein):**
- Rebuild yang gagal ? cek smali yang lo edit (bug syntax) ya jink
- Signing wajib kalau mau install
- Install requires USB debugging + ADB enabled

---

### Tahap 5 � Dynamic Analysis (Frida)

> **WAJIB, SERIUS:** Device dengan USB debugging enabled, atau emulator (genymotion preferred). Ini gak disiapin? Mending gak usah mulai, nanti gagal terus di tengah jalan.

```bash
# 1. Cek device & setup
adb devices
adb shell

# 2. Install APK kalau belum
adb install app.apk

# 3. Frida check-in
frida-ps -U | grep com.example   # app running?
```

**Basic Frida scripts:**

```javascript
// hook.js � Print semua method call di MainActivity
Java.perform(function() {
    console.log("Frida injected!");

    // Hook Java method & print args
    Java.use("com.example.app.MainActivity").login.overload(
        'java.lang.String', 'java.lang.String'
    ).implementation = function(user, pass) {
        console.log("login() called:");
        console.log("  username:", user);
        console.log("  password:", pass);
        return this.login(user, pass);
    };
});
```

```bash
# Jalankan script
frida -U -f com.example.app -l hook.js --no-pause
```

**Common Frida use cases:**

| Use Case | Frida Script |
|----------|-------------|
| SSL pinning bypass | Set SSL public key ke null / self-signed |
| Root detection bypass | Override `isRooted()` return false |
| Change return value | `.implementation = function() { return false; }` |
| Log sensitive data | Print semua argumen dari method target |
| Crypto key extraction | Hook `Cipher.init()` untuk capture key |

**SSL Pinning Bypass (one-liner):**

```bash
# Universal bypass via Frida
frida -U -f com.example.app -l ssl-bypass.js --no-pause
```

```javascript
// ssl-bypass.js
Java.perform(function() {
    try {
        var X509TrustManager = Java.use("javax.net.ssl.X509TrustManager");
        var SSLContext = Java.use("javax.net.ssl.SSLContext");
        var TrustManager = Java.registerClass({
            name: "com.bypass.TrustAll",
            implements: [X509TrustManager],
            methods: {
                checkClientTrusted: function(chain, authType) {},
                checkServerTrusted: function(chain, authType) {},
                getAcceptedIssuers: function() { return []; }
            }
        });
        var SSLContext_init = SSLContext.init.overload(
            "[Ljavax.net.ssl.KeyManager;", "[Ljavax.net.ssl.TrustManager;", "java.security.SecureRandom"
        );
        SSLContext_init.implementation = function(km, tm, sr) {
            SSLContext_init.call(this, km, [TrustManager.$new()], sr);
        };
        console.log("SSL pinning bypassed!");
    } catch(e) {
        console.log("SSL bypass failed:", e);
    }
});
```

---

### Tahap 6 � Native (.so) Analysis

Kalau aplikasi punya logic di native lib:

```bash
# 1. Extract .so
find apktool_out -name "*.so"

# 2. Cek symbols/strings
strings lib/arm64-v8a/libcore.so | grep -i secret
nm -D lib/arm64-v8a/libcore.so | grep java

# 3. Untuk deep analysis, export .so dari apk dan branchke reverse-binary module
```

---

## WORKFLOW PENDEK (QUICK RECAP)

```
1. apktool d app.apk -o out        # unpack
2. jadx -d jadx_out app.apk        # decompile
3. baca manifest + MainActivity    # pahami
4. edit smali Kalau perlu          # mod
5. apktool b out -o rebuild.apk    # rebuild
6. sign + install                  # deploy
7. Frida hook kalau dynamic test   # verify
```

---

## TEMUAN UMUM & SEVERITY

| Finding | Severity | Penjelasan |
|---------|----------|-----------|
| Sensitive data di SharedPreferences | High | Password/token plain text |
| SSL pinning tidak ada | Medium | MITM attack |
| Root detection bypassable | Medium | Security logic lemah |
| API key hardcoded | High | Credential leak |
| Insecure deserialization | High | RCE potential |
| WebView JavaScript enabled | Medium | XSS/JSI injection |
| Debuggable flag true | Low | Production debug mode |
| Insecure storage (SD card) | High | Data exposure |

---

## Tahap 7 � Root Android, Magisk & Root Detection (Buat Testing)

> Framing WAJIB: root di sini buat **testing aplikasi sendiri / berizin** � verifikasi apakah root detection app bisa di-bypass (jadi temuan), BUKAN ngeroot device orang lain. DASAR.

**Apa itu root Android:**
- Akses root/superuser lewat `su`. Cara umum: **Magisk** (systemless), custom recovery, atau patch `boot.img`.

**Magisk (paling umum):**
```bash
# Langkah umum (hanya di device lo sendiri, jangan asal):
# 1. Unlock bootloader resmi OEM
# 2. Ambil boot.img dari firmware, patch via Magisk App / magiskboot
# 3. Flash boot yang udah dipatch:
fastboot flash boot patched_boot.img
# Modul: /data/adb/modules/
# DenyList (penerus Magisk Hide): Magisk ? Settings ? Configure DenyList
```

**Root detection yang sering dipake app (untuk lo verifikasi di scope berizin):**

| Deteksi | Cara app cek | Catatan buat laporan |
|---------|--------------|----------------------|
| `su` binary | `File.exists` di path umum (`/system/bin/su`, dst) | Kalau gampang di-bypass ? finding "root detection lemah" |
| Package Magisk | query package manager nyari `topjohnwu.magisk` | App legit bisa di-test di device rooted |
| Play Integrity attestation | Google verdict (device integrity) | Rooted/flashed boot biasanya fail basic integrity |
| JNI / native check | cek PATH, exec `su`, cek mount | Hook native pakai Frida |

**Frida PoC (EDUKASI � jalanin di app LO SENDIRI, jangan di punya orang):**
```javascript
// root-detect-check.js � lihat logika deteksi (analisis, bukan curi)
Java.perform(function () {
    var File = Java.use("java.io.File");
    File.exists.implementation = function () {
        var p = this.getAbsolutePath();
        console.log("[File.exists] " + p);
        return this.exists();
    };
});
```

**Kesimpulan temuan:**
- Logic penting di balik root check yang bisa di-skip gampang ? severity **Medium** ("Root detection bypassable") � udah ada di tabel TEMUAN UMUM.
- App yang nyimpen secret & bergantung cuma di root check ? dinaikin (impact berkepanjangan).

**Cleanup:**
- Unroot: Magisk ? Uninstall, atau restore boot.img asli (`fastboot flash boot stock_boot.img`).

---

## PROHIBITED ACTIONS

1. **JANGAN** mod APK komersial untuk redistribute
2. **JANGAN** bypass IAP/in-app purchase (ilegal)
3. **JANGAN** hook aplikasi orang lain tanpa izin
4. **JANGAN** kejar data pribadi user lain (IDOR/info harvesting)
5. **JANGAN** malware/hook injection ke aplikasi legit tanpa consent

---

## Tahap 8 � Anti-Anti-Frida (Bypass Frida Detection)

> App makin pinter detect Frida. Lo harus counter-detect. Ini battle of wits ya tod.

### Kenapa App Detect Frida?

| Detection Method | Cara Kerja |
|------------------|------------|
| **Frida server port** (27042) | Cek apakah port 27042 terbuka |
| **Frida artifacts** | Cek file `/tmp/re.frida.server`, `frida-agent.so` |
| **Java reflection** | Cek `Runtime.exec()` ada frida process |
| **Native check** | Cek `/proc/self/maps` ada frida library |
| **Timing attack** | Frida inject delay ? app detect |
| **Socket probe** | Connect ke port 27042, cek response |

### Countermeasure 1: Change Frida Port

```bash
# Jalankan frida di port random
frida -H 0.0.0.0:9999 -f com.example.app -l script.js

# Atau ubah port frida server
frida-server -l 0.0.0.0:9999
```

### Countermeasure 2: Magisk + Zygisk (Recommended)

Zygisk = Magisk module yang inject code ke Zygote process. Lebih clean dari Riru.

```bash
# 1. Install Magisk (sudah dijelasin di root section)
# 2. Enable Zygisk: Magisk ? Settings ? Enable Zygisk
# 3. Install module:
#    - Shamiko (hide root dari app)
#    - PlayIntegrity Fix (bypass Play Integrity)
#    - Universal SafetyNet Fix

# 4. Configure DenyList:
#    Magisk ? Settings ? Configure DenyList ? pilih target app
```

### Countermeasure 3: Riru + LSPosed

Riru inject ke Zygote via library. LSPosed = Xposed framework di atas Magisk.

```bash
# 1. Install Riru (Magisk module)
# 2. Install LSPosed (Magisk module, enable Zygisk mode)
# 3. Install module:
#    - Hide My Applist (hide root dari app detection)
#    - XPrivacyLua (restrict permissions)
#    - SSLUnpinning (bypass SSL pinning via Xposed)
```

### Countermeasure 4: Frida Gadget (Tanpa Server)

Pakai Frida Gadget di dalam APK � gak perlu frida-server di device.

```bash
# 1. Inject frida-gadget.so ke lib/ arsitektur target
# 2. Load gadget di smali:
#    invoke-static {v0}, Lcom/frida/gadget/Main;->start()V

# 3. Connect dari PC:
#    frida -U Gadget -l script.js
```

### Countermeasure 5: Objection + Rootcloak

```bash
# Objection auto-bypass beberapa detection
objection -g com.example.app explore

# Setelah masuk objection:
android root disable        # disable root detection
android sslpinning disable  # disable SSL pinning

# Rootcloak module (Magisk)
# Install dari: https://github.com/nicholaschum/RootCloak
```

### Detection Bypass Table

| App Detection | Bypass |
|---------------|--------|
| Port 27042 check | Change port |
| `/proc/self/maps` check | Magisk DenyList + Shamiko |
| Java reflection | LSPosed + Hide My Applist |
| Native frida check | Frida Gadget (no server) |
| Timing check | Reduce hook overhead |
| File artifact check | Magisk Hide / Shamiko |

---

## Tahap 9 � Advanced Smali Patterns

> Smali = bahasa assembly untuk DEX. Basic patching udah ada di Tahap 3. Ini advanced patterns.

### Smali Data Types

```
V       = void
Z       = boolean
B       = byte
S       = short
C       = char
I       = int
J       = long (64-bit)
F       = float
D       = double
L...;   = object reference (e.g., Ljava/lang/String;)
[       = array (e.g., [I = int[], [[Ljava/lang/String; = String[][])
```

### Smali Method Calls

```smali
# Static method
invoke-static {v0, v1}, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;

# Instance method
invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

# Constructor
invoke-direct {v0}, Ljava/lang/String;-><init>(Ljava/lang/String;)V

# Super call
invoke-super {v0}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V
```

### Advanced Patching Patterns

**Bypass String Comparison:**
```smali
# Original: if (input.equals("secret"))
invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
move-result v2
if-eqz v2, :fail

# Patched: always return true
const/4 v2, 0x1
# (hapus if-eqz v2, :fail)
```

**Bypass Length Check:**
```smali
# Original: if (input.length() != 16)
invoke-virtual {v0}, Ljava/lang/String;->length()I
move-result v1
const/16 v2, 0x10
if-ne v1, v2, :fail

# Patched: skip length check
# hapus 3 baris di atas
```

**Bypass Null Check:**
```smali
# Original: if (obj == null) return null
if-eqz v0, :return_null

# Patched: hapus if-eqz
```

**Replace Method Return:**
```smali
# Original method
.method public isPremium()Z
    .locals 2
    # ... complex logic ...
    return v0
.end method

# Patched: always return true
.method public isPremium()Z
    .locals 1
    const/4 v0, 0x1
    return v0
.end method
```

### Smali Loop Patterns

```smali
# For loop (for i = 0; i < n; i++)
    const/4 v0, 0x0            # i = 0
    :loop_start
    if-ge v0, v1, :loop_end   # if i >= n, exit
    # ... loop body ...
    add-int/lit8 v0, v0, 0x1  # i++
    goto :loop_start
    :loop_end
```

### Smali Conditional Patterns

```smali
# if (a == b)
if-eq v0, v1, :true_label

# if (a != b)
if-ne v0, v1, :true_label

# if (a < b)
if-lt v0, v1, :true_label

# if (a > b)
if-gt v0, v1, :true_label

# if (a >= b)
if-ge v0, v1, :true_label

# if (a <= b)
if-le v0, v1, :true_label
```

---

## Tahap 10 � ProGuard / R8 Deobfuscation

> ProGuard/R8 = code obfuscator bawaan Android. Nama class/method di-random ? susah dibaca. Lo harus deobfuscate dulu.

### Ciri Obfuscated Code

```
# Class names aneh
a.b.c.d.e

# Method names aneh
a()
b()
c()

# String tetap terbaca (gak di-obfuscate)
"Lcom/example/api/secret"
```

### Deobfuscation Tools

```bash
# 1. ProGuard mappings (kalau ada)
# mapping.txt ? obfuscated name ? original name

# 2. JADX (auto-detect obfuscation)
jadx -d output app.apk
# JADX akan coba restore nama asli dari string references

# 3. ClassyShark
# GUI tool, auto-detect ProGuard

# 4. radare2 (manual analysis)
r2 app.apk
afl             # list functions
axt sym.method  # cross-references
```

### Manual Deobfuscation Tips

| Technique | Cara |
|-----------|------|
| **String analysis** | Cari string literal ? trace ke class/method |
| **Cross-reference** | Method yang dipanggil banyak = penting |
| **Inheritance** | Cari `extends Activity` ? itu MainActivity |
| **Interface** | Cari implementasi interface |
| **Annotation** | `@Override` ? method penting |
| **Resource reference** | `R.id.xxx` ? layout/ID |

### ReTrace / DeGuard

```bash
# ReTrace (ProGuard official)
retrace mapping.txt stacktrace.txt

# Online tools
# https://www.palmbeachstate.edu/prep/md/androguard.html
```

---

## Tahap 11 � APK Signing v2/v3

> APK signing udah evolusi. Signing v2/v3 lebih aman dari v1. Lo harus ngerti bedanya.

### Signing Versions

| Version | Introduced | Security |
|---------|------------|----------|
| v1 | Android 1.0 | JAR signing, hanya file-by-file |
| v2 | Android 7.0 (API 24) | Full-file signature, lebih cepat |
| v3 | Android 9.0 (API 28) | Key rotation support |

### Cek Signing Version

```bash
# aapt2
aapt2 dump badging app.apk | grep "versionCode"

# apksigner
apksigner verify --print-certs app.apk

# keytool
keytool -printcert -jarfile app.apk
```

### Signing v1 (JAR Signing)

```bash
# Sign dengan JAR signer
jarsigner -keystore debug.keystore app.apk alias_name

# Verify
jarsigner -verify -verbose app.apk
```

### Signing v2 (Full APK Signature)

```bash
# apksigner (recommended)
apksigner sign --ks debug.keystore --ks-pass pass:android app.apk

# Verify
apksigner verify --verbose app.apk
```

### Signing v3 (Key Rotation)

```bash
# Generate new signing key
keytool -genkeypair -alias new_key -keyalg RSA -keysize 2048 -validity 10000

# Sign dengan rotation support
apksigner sign --ks new.keystore --v3-signing-enabled true app.apk

# Verify
apksigner verify --verbose app.apk
```

### What Happens During Mod

```
1. Unpack (apktool d)    ? Signature invalidated
2. Modify smali/resource ? Perubahan content
3. Rebuild (apktool b)   ? New unsigned APK
4. Zipalign              ? Optimize alignment
5. Re-sign               ? New signature (debug/production key)
```

### Key Points

| Point | Explanation |
|-------|-------------|
| Debug key | Untuk testing, gak production |
| Release key | Untuk Google Play |
| Key rotation | v3 support ganti key tanpa uninstall |
| Signature mismatch | Install gagal (kalau enforce signing) |

---

## Tahap 12 � Frida Advanced Techniques

> Basic Frida udah ada di Tahap 5. Ini advanced: Interceptor, NativeFunction, Memory, anti-anti-Frida.

### Interceptor (Native Function Hook)

```javascript
// Hook native function di .so
Interceptor.attach(Module.findExportByName("libnative.so", "check_license"), {
    onEnter: function(args) {
        // args[0], args[1], ... = function arguments
        console.log("check_license called with:", args[0]);
        this.arg0 = args[0]; // save for onLeave
    },
    onLeave: function(retval) {
        // retval = return value
        console.log("check_license returned:", retval);
        retval.replace(ptr(1)); // force return 1 (true)
    }
});
```

### NativeFunction (Call Native dari JS)

```javascript
// Call C function dari Frida
var malloc = new NativeFunction(
    Module.findExportByName(null, "malloc"),
    'pointer',
    ['uint']
);
var buf = malloc(1024);
console.log("Allocated at:", buf);
```

### Memory Operations

```javascript
// Read memory
var ptr = ptr("0x12345678");
var data = Memory.readByteArray(ptr, 64);
console.log(hexdump(data));

// Write memory
Memory.writeByteArray(ptr, [0x90, 0x90, 0x90]); // NOP slide

// Scan memory
Memory.scan(ptr("0x10000000"), 0x10000, "48 89 E5", {
    onMatch: function(address, size) {
        console.log("Found at:", address);
    },
    onComplete: function() {}
});
```

### Java ClassLoader Hook

```javascript
// Hook class loading
Java.enumerateLoadedClasses({
    onMatch: function(className) {
        if (className.includes("com.target.app")) {
            console.log("Loaded:", className);
        }
    },
    onComplete: function() {}
});
```

### Frida Gadget (No Server)

```bash
# 1. Download frida-gadget.so
# https://github.com/FRIDA/frida/releases

# 2. Inject ke APK
# a. Decompile APK
apktool d target.apk

# b. Copy frida-gadget.so ke lib/arm64-v8a/
cp frida-gadget.so target.apk/lib/arm64-v8a/

# c. Edit smali (Application class)
# Tambahkan di onCreate():
# invoke-static {}, Lcom/frida/gadget/Main;->start()V

# d. Rebuild & sign
apktool b target.apk
apksigner sign --ks debug.keystore target.apk
```

### Anti-Anti-Frida Techniques

| Detection | Bypass |
|-----------|--------|
| Port 27042 | Change port: `frida-server -l 0.0.0.0:9999` |
| `/proc/self/maps` check | Zygisk + Shamiko |
| Java reflection | LSPosed + Hide My Applist |
| Native .so check | Frida Gadget (no server) |
| Timing | Reduce hook overhead |
| Socket probe | Use Gadget |

### Frida Scripts Collection

```javascript
// 1. SSL Unpinning (universal)
Java.perform(function() {
    var TrustManager = Java.registerClass({
        name: 'com.bypass.TrustManager',
        implements: [Java.use('javax.net.ssl.X509TrustManager')],
        methods: {
            checkClientTrusted: function() {},
            checkServerTrusted: function() {},
            getAcceptedIssuers: function() { return []; }
        }
    });
    var SSLContext = Java.use('javax.net.ssl.SSLContext');
    SSLContext.init.overload('[Ljavax.net.ssl.KeyManager;',
        '[Ljavax.net.ssl.TrustManager;', 'java.security.SecureRandom')
        .implementation = function(km, tm, sr) {
        this.init(km, [TrustManager.$new()], sr);
    };
});

// 2. Root Detection Bypass
Java.perform(function() {
    var RootBeer = Java.use("com.scottyab.rootbeer.RootBeer");
    RootBeer.isRooted.implementation = function() {
        return false;
    };
});

// 3. Tamper String
Java.perform(function() {
    var String = Java.use("java.lang.String");
    String.equals.implementation = function(other) {
        if (other === "expected_password") {
            return true;
        }
        return this.equals(other);
    };
});
```

---

## TOOLS CHEAT SHEET

| Tool | Fungsi | Command |
|------|--------|---------|
| jadx | Decompile DEX ? Java | `jadx -d out app.apk` |
| apktool | Unpack/rebuild/smali | `apktool d` / `apktool b` |
| aapt | Manifest/badge info | `aapt dump badging app.apk` |
| zipalign | Align APK | `zipalign -v 4 in.apk out.apk` |
| apksigner | Sign APK | `apksigner sign --ks debug.jks` |
| adb | Device control | `adb install`, `adb push`, `adb logcat` |
| frida | Dynamic hook | `frida -U -f pkg -l script.js` |
| dex2jar + jd-cli | Alt decompiler | `d2j-dex2jar app.apk` |
| dexdump | DEX structure | `dexdump -d classes.dex` |
| ClassyShark | APK analysis GUI | `java -jar ClassyShark.jar` |
| Objection | Runtime exploration | `objection -g pkg explore` |
| retrace | ProGuard deobfuscate | `retrace mapping.txt stack.txt` |

---

## Tahap 13 � WebView Exploitation

> WebView = komponen Android yang render web di dalam app. Attack surface: JavaScript bridge, file access, intent handling.

### Cek WebView di Manifest

```xml
<!-- AndroidManifest.xml -->
<activity android:name=".WebViewActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="myapp" />
    </intent-filter>
</activity>
```

### Common WebView Vulnerabilities

| Vulnerability | Kenapa |
|---------------|--------|
| `setJavaScriptEnabled(true)` | JS bisa akses native code |
| `setAllowFileAccess(true)` | Baca file local |
| `setAllowContentAccess(true)` | Akses content provider |
| `addJavascriptInterface()` | Bridge ke Java |
| `setAllowFileAccessFromFileURLs(true)` | Baca file dari URL lain |
| `setAllowUniversalAccessFromFileURLs(true)` | Universal file access |

### Frida Hook WebView

```javascript
// Hook addJavascriptInterface
Java.perform(function() {
    var WebView = Java.use("android.webkit.WebView");
    WebView.addJavascriptInterface.implementation = function(obj, name) {
        console.log("[WebView] addJavascriptInterface: " + name);
        console.log("[WebView] Methods:");
        var methods = obj.getClass().getMethods();
        for (var i = 0; i < methods.length; i++) {
            console.log("  - " + methods[i].getName());
        }
        return this.addJavascriptInterface(obj, name);
    };
});

// Hook loadUrl
Java.perform(function() {
    var WebView = Java.use("android.webkit.WebView");
    WebView.loadUrl.overload('java.lang.String').implementation = function(url) {
        console.log("[WebView] loadUrl: " + url);
        return this.loadUrl(url);
    };
});
```

### WebView JavaScript Injection

```javascript
// Hook JavaScript execution
Java.perform(function() {
    var WebView = Java.use("android.webkit.WebView");
    WebView.evaluateJavascript.overload('java.lang.String', 'android.webkit.ValueCallback').implementation = function(script, callback) {
        console.log("[WebView] evaluateJavascript: " + script);
        return this.evaluateJavascript(script, callback);
    };
});
```

### WebView File Access Exploitation

```javascript
// Cek file access settings
Java.perform(function() {
    var WebView = Java.use("android.webkit.WebView");
    WebView.setAllowFileAccess.implementation = function(flag) {
        console.log("[WebView] setAllowFileAccess: " + flag);
        return this.setAllowFileAccess(flag);
    };
    
    WebView.setAllowFileAccessFromFileURLs.implementation = function(flag) {
        console.log("[WebView] setAllowFileAccessFromFileURLs: " + flag);
        return this.setAllowFileAccessFromFileURLs(flag);
    };
    
    WebView.setAllowUniversalAccessFromFileURLs.implementation = function(flag) {
        console.log("[WebView] setAllowUniversalAccessFromFileURLs: " + flag);
        return this.setAllowUniversalAccessFromFileURLs(flag);
    };
});
```

### WebView Exploit Payload

```
# File read via WebView
file:///data/data/com.target.app/shared_prefs/prefs.xml

# Intent redirect
intent:#Intent;component=com.target.app/.AdminActivity;end

# JavaScript to Java call
javascript:Android.getClass().getDeclaredMethod("adminAction").invoke()
```

---

## Tahap 14 � Content Provider Exploitation

> Content Provider = database sharing antar app. Sering gak di-secure ? SQL injection, path traversal, data leak.

### Cek Content Provider

```bash
# List content providers
adb shell dumpsys package providers

# Query provider
adb shell content query --uri content://com.target.app.provider/users

# Cek exported provider
adb shell dumpsys package com.target.app | grep -A5 "Provider"
```

### Content Provider Attack Types

| Attack | Payload |
|--------|---------|
| **SQL Injection** | `' OR 1=1--` |
| **Path Traversal** | `../../etc/passwd` |
| **Data Leak** | Query semua data |
| **File Read** | `content://com.target.app.provider/../../etc/passwd` |

### Frida Hook Content Provider

```javascript
// Hook Content Provider query
Java.perform(function() {
    var ContentProvider = Java.use("android.content.ContentProvider");
    ContentProvider.query.overload(
        'android.net.Uri', '[Ljava.lang.String;', 'java.lang.String',
        '[Ljava.lang.String;', 'java.lang.String'
    ).implementation = function(uri, projection, selection, selectionArgs, sortOrder) {
        console.log("[ContentProvider] query:");
        console.log("  URI: " + uri);
        console.log("  Selection: " + selection);
        return this.query(uri, projection, selection, selectionArgs, sortOrder);
    };
});
```

### SQL Injection via Content Provider

```
# Via adb
adb shell content query --uri content://com.target.app.provider/users --where "username='admin' OR 1=1"

# Via curl (kalau provider exposed via HTTP)
curl "http://localhost/content/users?username=admin'%20OR%201=1"
```

### Path Traversal via Content Provider

```
# Read sensitive files
content://com.target.app.provider/../../data/data/com.target.app/databases/db

# Via adb
adb shell content query --uri content://com.target.app.provider/../../etc/hosts
```

---

## Tahap 15 � Intent Injection / Activity Hijacking

> Intent = pesan antar komponen. Kalau app gak validate input ? intent injection, activity hijacking.

### Cek Exported Components

```bash
# List exported activities
adb shell dumpsys package com.target.app | grep -A3 "Activity"

# Launch activity
adb shell am start -n com.target.app/.TargetActivity

# With intent
adb shell am start -n com.target.app/.TargetActivity --es "key" "value"
```

### Intent Injection Types

| Type | Cara |
|------|------|
| **Activity Hijacking** | Start activity tanpa auth |
| **Intent Redirect** | Inject component name |
| **Extra Injection** | Inject malicious extras |
| **URI Scheme Abuse** | Custom scheme ? hijack |

### Frida Hook Intent

```javascript
// Hook startActivity
Java.perform(function() {
    var Activity = Java.use("android.app.Activity");
    Activity.startActivity.implementation = function(intent) {
        console.log("[Activity] startActivity:");
        console.log("  Component: " + intent.getComponent());
        console.log("  Action: " + intent.getAction());
        console.log("  Data: " + intent.getDataString());
        return this.startActivity(intent);
    };
});
```

### Intent Injection Payload

```
# Via adb
adb shell am start -n com.target.app/.AdminActivity

# With extras
adb shell am start -n com.target.app/.VulnerableActivity \
    --es "url" "javascript:alert(1)" \
    --ez "debug" true

# Via URI scheme
am start -a android.intent.action.VIEW -d "myapp://admin"
```

---

## Tahap 16 � Network Traffic Interception Workflow

> Step-by-step setup intercept traffic dari Android app ke Burp/Charles.

### Setup Burp Suite

```bash
# 1. Install Burp Suite
# https://portswigger.net/burp/communitydownload

# 2. Start Burp ? Proxy ? Listen 127.0.0.1:8080

# 3. Install CA certificate di Android:
#    a. Buka http://burp ? CA Certificate ? Download
#    b. Install ke device

# 4. Configure Android proxy:
#    Settings ? WiFi ? Long press network ? Modify ? Advanced ? Proxy
#    Manual: 192.168.1.X:8080 (IP komputer lo)
```

### Setup Charles Proxy

```bash
# 1. Install Charles
# https://www.charlesproxy.com/

# 2. Start Charles ? Proxy ? Proxy Settings ? Port 8888

# 3. Install CA:
#    Help ? SSL Proxying ? Install Charles Root Certificate

# 4. Configure Android proxy (sama seperti Burp)
```

### Bypass Certificate Pinning

```bash
# Method 1: Objection
objection -g com.target.app explore
ios sslpinning disable
android sslpinning disable

# Method 2: Frida script (udah ada di Tahap 5)

# Method 3: SSL Unpinning module (Magisk/LSPosed)
```

### Analyze Traffic

```bash
# Filter by host
# Burp: Target ? Filter ? Host = target.com

# Filter by protocol
# Wireshark: http || tls

# Extract endpoints
# Burp: Target ? Site map ? Select all

# Find sensitive data
# Filter: password, token, key, secret
```

### Network Analysis Checklist

| Check | Tool |
|-------|------|
| HTTP requests | Burp HTTP history |
| HTTPS certificates | Burp TLS tab |
| API endpoints | Site map |
| Auth tokens | Request headers |
| Sensitive data | Request/response body |
| Cookies | Cookie jar |
| WebSocket | Burp WebSocket history |

---

## RESOURCES & NEXT STEPS

- **OWASP Mobile Security Testing Guide**: https://mas.owasp.org/
- **Frida official docs**: https://frida.re/docs/
- **Mobile Security Framework (MobSF)**: automation untuk static analysis
- **Objection** (runtime mobile exploration): `pip install objection`
- **Labs**: HackTheBox mobile, OWASP Juice Shop mobile

**Pertumbuhan skill:**
1. Mulai dengan **sample app** sendiri
2. Naik ke open-source app dari GitHub
3. Baru ke CTF mobile challenges
4. Terakhir: authorized bug bounty scope

---

## Sub-Modules � Deep Dives

| Sub-Module | Trigger | Lokasi |
|------------|---------|--------|
| **SSL Pinning Bypass** | SSL pinning bypass Android, certificate trust | `ssl-pinning/SKILL.md` |

---

## See Also (Module Terkait)

| Jika Task Lo... | Module Lain yang Relevan |
|-----------------|-------------------------|
| Native .so analysis | `core/reverse-binary/SKILL.md` — Binary RE |
| Server-side API | `core/pentest-web/SKILL.md` — Web pentest |
| SSL certificate bypass | `core/mobile-android/ssl-pinning/SKILL.md` — SSL pinning |
| C2 communication | `core/network-recon/SKILL.md` — Network analysis |
| Malware detection | `core/malware-analysis/SKILL.md` — Malware analysis |