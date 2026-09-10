# Security Policy — 0xNxx-skill

Skill ini adalah **attack surface**: fork/install nyasar bisa menyisipkan instruksi jahat ke dalam
`SKILL.md`, script installer, atau resource lain. Dokumen ini menjelaskan model keamanan yang
sudah diimplementasikan di repo ini dan cara melaporkan masalah.

## Model Integritas (yang sudah dijalankan)

| Lapisan | File | Fungsi |
|---------|------|--------|
| Baseline hash | `trust-manifest.json` | SHA-256 + ukuran tiap file skill, plus allowlist host eksternal |
| Verifikasi | `scripts/verify-skill.ps1` | Cek integritas, cakupan file, host tak dikenal, pola skill jahat |
| Regenerasi | `scripts/update-manifest.ps1` | Menghasilkan ulang `trust-manifest.json` setelah edit resmi |
| Kebijakan | `references/skill-security-playbook.md` | Playbook deteksi & respons skill rusak/poisoned |
| Aturan agent | `SKILL.md` → "Keamanan Skill (Protokol Biar Gak Ketipu)" | Guardrail runtime untuk AI |

## Cara Verifikasi Install

```powershell
# dari root skill:
powershell -ExecutionPolicy Bypass -File scripts/verify-skill.ps1
```

Output dianggap TIDAK AMAN kalau muncul:

- `HASH-MISMATCH` — file diubah dari baseline resmi
- `UNLISTED` — file baru yang tidak ada di manifest (kemungkinan injeksi)
- `HOST-NOT-ALLOWED` — URL ke host yang tidak pernah disetujui (kemungkinan exfil)
- `SUSPICIOUS-PATTERN` — pola skill jahat (instruksi tersembunyi, reverse shell, dll)

## Allowlist Host

Host eksternal yang boleh dirujuk skill ada di `trust-manifest.json` → `allowlist.hosts`.
Menambah URL baru = **keputusan sadar**, tidak otomatis ikut saat `update-manifest` — kalau
host baru muncul dan gagal verifikasi, periksa dulu sumbernya sebelum ditambahkan.

## Melaporkan Kerentanan

- Buka issue di issue tracker resmi repo (jangan pakai fork rahasia / DM pribadi tanpa bukti).
- Sertakan: versi skill, file yang mencurigakan, output `verify-skill.ps1`, dan langkah reproduksi.
- Jangan publish detail exploit di publik sebelum dikonfirmasi.

## Dukungan

Hanya rilis terbaru yang didukung. Install versi lama tanpa verifikasi hash = tanggung sendiri.