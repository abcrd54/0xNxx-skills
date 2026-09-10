---
name: forensics
description: |
  Digital forensics, DFIR, memory analysis, disk forensics, steganography, PCAP analysis.
  Kata kunci: forensics, dfir, volatility, memory dump, pcap, wireshark, steganography, steghide, binwalk, autopsy, sleuth kit.
---

# SKILL: Digital Forensics — Memory + Disk + Network + Stego

> **Trigger:** User minta analisis memory dump, PCAP, steganography, atau DFIR.

---

## 0. Setup

```bash
# Volatility (memory forensics)
pip3 install volatility3

# Sleuth Kit (disk forensics)
apt install sleuthkit -y

# Steganography
apt install steghide -y
apt install zsteg -y
apt install binwalk -y
apt install foremost -y

# Network forensics
apt install wireshark tshark -y
apt install tcpdump -y

# Image tools
apt install imagemagick -y
apt install exiftool -y
```

---

## 1. Memory Forensics — Volatility

### Basic Usage

```bash
# Identify profile
volatility3 -f memory.dmp windows.info

# List processes
volatility3 -f memory.dmp windows.pslist

# Process tree
volatility3 -f memory.dmp windows.pstree

# Process scan (include unlinked)
volatility3 -f memory.dmp windows.psscan

# Network connections
volatility3 -f memory.dmp windows.netscan

# Network sockets
volatility3 -f memory.dmp windows.sockscan

# DLLs
volatility3 -f memory.dmp windows.dlllist

# Handles
volatility3 -f memory.dmp windows.handles

# Command line
volatility3 -f memory.dmp windows.cmdline

# Registry hives
volatility3 -f memory.dmp windows.registry.hivelist

# Dump process
volatility3 -f memory.dmp windows.memmap --pid <PID> --dump

# Screenshot
volatility3 -f memory.dmp windows.screenshot --pid <PID>

# File scan
volatility3 -f memory.dmp windows.filescan

# Dump file
volatility3 -f memory.dmp windows.dumpfiles --virtaddr <ADDRESS>
```

### Volatility Plugins Cheat Sheet

| Plugin | Fungsi |
|--------|--------|
| `windows.info` | OS profile info |
| `windows.pslist` | Process list |
| `windows.pstree` | Process tree |
| `windows.psscan` | Hidden process scan |
| `windows.netscan` | Network connections |
| `windows.sockscan` | Socket scan |
| `windows.cmdline` | Command line args |
| `windows.dlllist` | Loaded DLLs |
| `windows.handles` | Open handles |
| `windows.registry.hivelist` | Registry hives |
| `windows.registry.userassist` | UserAssist (recent apps) |
| `windows.registry.amcache` | Amcache (installed apps) |
| `windows.registry.srum` | SRUM (network usage) |
| `windows.malfind` | Detect injected code |
| `windows.vadinfo` | VAD (virtual memory) |
| `windows.filescan` | File objects |
| `windows.dumpfiles` | Dump files from memory |
| `windows.screenshot` | Take screenshot |

### Memory Analysis Workflow

```
MEMORY DUMP DITERIMA
│
├─→ FASE 1: IDENTIFIKASI
│   volatility3 -f dump.dmp windows.info
│   # Cek OS version, architecture
│
├─→ FASE 2: PROCESS ANALYSIS
│   volatility3 -f dump.dmp windows.pslist
│   volatility3 -f dump.dmp windows.pstree
│   # Cari:
│   # - Proses aneh (nama aneh, PID aneh)
│   # - Proses tanpa parent (orphan)
│   # - Proses dengan nama mirip system
│
├─→ FASE 3: NETWORK
│   volatility3 -f dump.dmp windows.netscan
│   # Cari:
│   # - Koneksi ke IP asing
│   # - Port aneh (C2, reverse shell)
│   # - Established connections
│
├─→ FASE 4: COMMAND LINE
│   volatility3 -f dump.dmp windows.cmdline
│   # Cari:
│   # - PowerShell suspicious
│   # - cmd.exe execution
│   # - Certutil, bitsadmin (download tools)
│
├─→ FASE 5: MALWARE DETECTION
│   volatility3 -f dump.dmp windows.malfind
│   # Detect injected code, hollowed processes
│
├─→ FASE 6: PERSISTENCE
│   volatility3 -f dump.dmp windows.registry.hivelist
│   # Check Run keys, services, scheduled tasks
│
└─→ FASE 7: DUMP EVIDENCE
    # Dump suspicious processes
    # Extract files from memory
    # Take screenshots
```

---

## 2. Disk Forensics — Sleuth Kit

### TSK Commands

```bash
# List partitions
mmls disk.img

# Mount filesystem
mkdir /mnt/forensic
mount -o ro,loop disk.img /mnt/forensic

# List files
fls -r /mnt/forensic

# Find deleted files
fls -r -d /mnt/forensic

# File metadata
istat /mnt/forensic/path/to/file

# Extract file
icat /mnt/forensic inode_number > extracted_file

# String search
strings /mnt/forensic/path/to/file | grep -i "password"

# Hash all files
find /mnt/forensic -type f -exec md5sum {} \;
```

### Autopsy GUI

```bash
# Start Autopsy
autopsy

# Or via docker
docker run -it -p 9999:9999 -v /path/to/evidence:/evidence sleuthkit/autopsy
```

---

## 3. Network Forensics — PCAP

### tshark Commands

```bash
# Basic info
tshark -r capture.pcap

# Filter by protocol
tshark -r capture.pcap -Y "http"
tshark -r capture.pcap -Y "dns"
tshark -r capture.pcap -Y "tcp.port == 443"

# Extract HTTP objects
tshark -r capture.pcap --export-objects http,exported_files/

# Extract DNS queries
tshark -r capture.pcap -Y "dns" -T fields -e dns.qry.name | sort -u

# Extract URLs
tshark -r capture.pcap -Y "http.request" -T fields -e http.host -e http.request.uri

# Follow TCP stream
tshark -r capture.pcap -z "follow,tcp,ascii,0"

# Extract files
tshark -r capture.pcap --export-objects smb,exported_files/

# Statistics
tshark -r capture.pcap -z conv,ip
tshark -r capture.pcap -z http,tree
tshark -r capture.pcap -z dns,tree

# Extract credentials
tshark -r capture.pcap -Y "http.authorization" -T fields -e http.authorization

# Extract cookies
tshark -r capture.pcap -Y "http.cookie" -T fields -e http.cookie
```

### PCAP Analysis Workflow

```
PCAP DITERIMA
│
├─→ FASE 1: OVERVIEW
│   tshark -r capture.pcap -z conv,ip
│   # See who talked to whom
│
├─→ FASE 2: DNS ANALYSIS
│   tshark -r capture.pcap -Y "dns" -T fields -e dns.qry.name | sort -u
│   # Look for:
│   # - C2 domains
│   # - DGA-like domains
│   # - DNS tunneling
│
├─→ FASE 3: HTTP ANALYSIS
│   tshark -r capture.pcap -Y "http.request" -T fields -e http.host -e http.request.uri
│   tshark -r capture.pcap --export-objects http,exported/
│   # Look for:
│   # - Malicious downloads
│   # - C2 communication
│   # - Data exfiltration
│
├─→ FASE 4: TLS ANALYSIS
│   tshark -r capture.pcap -Y "tls.handshake" -T fields -e tls.handshake.extensions_server_name
│   # Check certificates
│
├─→ FASE 5: FILE EXTRACTION
│   tshark -r capture.pcap --export-objects http,extracted/
│   tshark -r capture.pcap --export-objects smb,extracted/
│   # Analyze extracted files
│
└─→ FASE 6: REPORT
    # Timeline of events
    # IOCs extracted
    # Suspicious communications
```

---

## 4. Steganography

### Image Steganography

```bash
# steghide (JPEG/BMP)
steghide extract -sf image.jpg
steghide extract -sf image.jpg -p password
steghide info image.jpg

# zsteg (PNG/BMP)
zsteg image.png
zsteg -a image.png  # All methods
zsteg image.png -b 1  # LSB 1 bit

# binwalk
binwalk image.png
binwalk -e image.png  # Extract

# exiftool
exiftool image.png

# strings
strings image.png | grep -i "flag"

# xxd (hex analysis)
xxd image.png | head -100

# foremost
foremost -i image.png -o output/
```

### Audio Steganography

```bash
# Spectrogram (hidden image in audio)
# Use Audacity → Spectrogram view

# DeepSound
# GUI tool for hidden data in audio

# Sonic visualizer
# Visual analysis of audio files
```

### Document Steganography

```bash
# Word documents
unzip document.docx -d extracted/
# Check embedded objects, macros

# PDF
pdf-parser.py document.pdf
# Check for JavaScript, embedded files

# PowerPoint
unzip presentation.ppt -d extracted/
# Check slide transitions, embedded media
```

### Stego Detection

| Technique | Indicators |
|-----------|------------|
| LSB | Statistical anomaly in color channels |
| DCT | JPEG compression artifacts |
| Palette | Unusual color palette entries |
| Metadata | Comments, descriptions |
| File appended | Extra data after EOF |

---

## 5. File Analysis

### File Type Identification

```bash
# Basic
file mystery_file

# Detailed
file -b mystery_file
file -i mystery_file

# Magic bytes
xxd mystery_file | head -1

# Entropy analysis
binwalk -E mystery_file
```

### Common File Signatures

| Type | Hex | ASCII |
|------|-----|-------|
| PNG | `89 50 4E 47` | `.PNG` |
| JPEG | `FF D8 FF` | - |
| GIF | `47 49 46 38` | `GIF8` |
| PDF | `25 50 44 46` | `%PDF` |
| ZIP | `50 4B 03 04` | `PK..` |
| RAR | `52 61 72 21` | `Rar!` |
| 7Z | `37 7A BC AF` | `7z..` |
| GZIP | `1F 8B` | - |
| PE | `4D 5A` | `MZ` |
| ELF | `7F 45 4C 46` | `.ELF` |

### String Extraction

```bash
# Basic strings
strings file

# Unicode strings
strings -el file

# Minimum length
strings -n 8 file

# Grep specific
strings file | grep -iE "flag|key|pass|token|http"
```

---

## 6. Steganography Challenges

### CTF Stego Workflow

```
FILE DITERIMA
│
├─→ FASE 1: TRIAGE
│   file image.png
│   exiftool image.png
│   strings image.png | head -50
│
├─→ FASE 2: BINWALK
│   binwalk image.png
│   binwalk -e image.png
│   # Check for embedded files
│
├─→ FASE 3: LSB ANALYSIS
│   zsteg -a image.png
│   # Check all LSB methods
│
├─→ FASE 4: STEGHIDE
│   steghide info image.jpg
│   # Try with empty password
│   steghide extract -sf image.jpg
│
├─→ FASE 5: HEX EDITOR
│   xxd image.png | tail -100
│   # Check for appended data
│
├─→ FASE 6: SPECTROGRAM
│   # Open in Audacity
│   # Check spectrogram view
│
└─→ FASE 7: ADVANCED
    # Check color channels
    # Check metadata
    # Try multiple tools
```

### Stego Tools Reference

| Tool | File Types | Method |
|------|------------|--------|
| steghide | JPEG, BMP, WAV, AU | DCT, LSB |
| zsteg | PNG, BMP | LSB, palette |
| binwalk | All | Embedded files |
| exiftool | All | Metadata |
| stegsolve | PNG, BMP | Visual analysis |
| LSB隐写 | PNG | Bit planes |

---

## 7. DFIR Workflow

### Incident Response

```
INCIDENT DITERIMA
│
├─→ FASE 1: IDENTIFICATION
│   # Cek alert/anomali
│   # Cek logs
│   # Cek network traffic
│
├─→ FASE 2: COLLECTION
│   # Memory dump
│   # Disk image
│   # Network capture
│   # Log collection
│
├─→ FASE 3: ANALYSIS
│   # Memory analysis (Volatility)
│   # Disk forensics (TSK)
│   # Network forensics (tshark)
│   # Log analysis
│
├─→ FASE 4: TIMELINE
│   # Buat timeline kejadian
│   # Correlate artifacts
│
├─→ FASE 5: CONTAINMENT
│   # Isolasi affected systems
│   # Block malicious IPs/domains
│
├─→ FASE 6: ERADICATION
│   # Remove malware
│   # Patch vulnerabilities
│
└─→ FASE 7: RECOVERY & REPORT
    # Restore systems
    # Documentation
    # Lessons learned
```

---

## 8. Tools Reference

| Category | Tools |
|----------|-------|
| Memory | Volatility, Rekall |
| Disk | Sleuth Kit, Autopsy, FTK Imager |
| Network | Wireshark, tshark, NetworkMiner |
| Stego | steghide, zsteg, stegsolve, binwalk |
| Hash | hashid, hashcat, john |
| Imaging | dd, FTK Imager |
| Timeline | Plaso/log2timeline |
| Log | Splunk, ELK |

---

*End skill — gas lanjut, jangan mandek ya tod.*

---

## See Also (Module Terkait)

| Jika Task Lo... | Module Lain yang Relevan |
|-----------------|-------------------------|
| Malware in artifacts | `core/malware-analysis/SKILL.md` — Malware analysis |
| PCAP network traffic | `core/network-recon/SKILL.md` — Network analysis |
| Memory forensics | `core/reverse-binary/SKILL.md` — Binary analysis |
| Encrypted data | `core/crypto/SKILL.md` — Crypto |
| Disk images | `core/forensics/SKILL.md` — Full forensics |
