# verify-skill.ps1 - Integrity + tamper scan for the 0xNxx-skill package.
# Checks: file hashes vs trust-manifest.json, unlisted files, unknown external
# hosts, and known malicious/pod intersection patterns.
# Exit code: 0 = clean, 1 = problems found.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$manifestPath = Join-Path $root 'trust-manifest.json'

if (-not (Test-Path -LiteralPath $manifestPath)) {
    Write-Host "[FATAL] trust-manifest.json not found. Run scripts/update-manifest.ps1 first." -ForegroundColor Red
    exit 1
}

$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$report   = [System.Collections.Generic.List[object]]::new()
$failed   = $false

function Add-Report([string]$path, [string]$type, [string]$detail) {
    $report.Add([pscustomobject]@{ Path = $path; Type = $type; Detail = $detail })
    if ($type -in @('HASH-MISMATCH', 'UNLISTED', 'HOST-NOT-ALLOWED', 'MISSING')) { $script:failed = $true }
}

$known = @{}
$manifest.files.PSObject.Properties | ForEach-Object { $known[$_.Name] = $_.Value }

# 1) integrity + coverage
$onDisk = @()
Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object { $_.FullName -notmatch '\\\.git\\' } | ForEach-Object {
    $rel = $_.FullName.Substring($root.Length + 1) -replace '\\', '/'
    $onDisk += $rel
    if ($rel -eq 'trust-manifest.json') { return }
    if (-not $known.ContainsKey($rel)) {
        Add-Report $rel 'UNLISTED' 'File ada tapi tidak tercatat di manifest (potensi injeksi).'
        return
    }
    $h = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    if ($h -ne $known[$rel].sha256) {
        Add-Report $rel 'HASH-MISMATCH' ("expected " + $known[$rel].sha256 + " got " + $h)
    }
}
foreach ($m in ($known.Keys | Where-Object { $_ -notin $onDisk })) {
    Add-Report $m 'MISSING' 'File tercatat di manifest tapi tidak ada di disk.'
}

# 2) allowlist host scan (real exfil dam) - excludes trust-manifest.json itself
$allowHosts    = @($manifest.allowlist.hosts)
$suspectedHosts = @{}
Get-ChildItem -LiteralPath $root -Recurse -File -Include *.md, *.json, *.ps1, *.sh |
    Where-Object { $_.Name -notin @('trust-manifest.json', 'verify-skill.ps1', 'update-manifest.ps1') -and $_.FullName -notmatch '\\\.git\\' } |
    ForEach-Object {
        $rel  = $_.FullName.Substring($root.Length + 1) -replace '\\', '/'
        $text = Get-Content -Raw -LiteralPath $_.FullName
foreach ($m in [regex]::Matches($text, '(?i)https?://([^/\s"''`),]+)')) {
            $raw   = $m.Groups[1].Value
            $hname = ($raw -replace ':\d+$', '' -replace '\.[/,]+$', '').Replace('[','').Replace(']','').TrimEnd(':').TrimEnd(',','.').Trim().ToLowerInvariant()
            $isLo  = $hname -match '^(localhost|::1|\d{1,3}(\.\d{1,3}){3}|\d{7,10})$'
            if ((-not $isLo) -and ($hname -notin $allowHosts)) {
                if (-not $suspectedHosts.ContainsKey($rel)) { $suspectedHosts[$rel] = @() }
                $suspectedHosts[$rel] += $hname
            }
        }
    }
foreach ($entry in $suspectedHosts.GetEnumerator()) {
    foreach ($h in ($entry.Value | Sort-Object -Unique)) {
        Add-Report $entry.Key 'HOST-NOT-ALLOWED' ("https://$h tidak ada di allowlist (potensi callback/exfil).")
    }
}

# 3) poisoned-pattern scan (self files & playbook excluded to avoid self-trigger)
$patterns = @(
    '(?i)do not (mention|tell) (this|that|the user)',
    '(?i)jangan (bilang|sebut|kasih ?tau|tampilkan)',
    '(?i)ignore (all )?(previous|prior) instructions',
    '(?i)abaikan (semua )?(instruksi|perintah) (sebelumnya|di atas|diatas)',
    '(?i)override (your )?(instructions|system prompt)',
    '(?i)override (instruksi|konteks|perintah)',
    '(?i)hidden (instruction|command|feature)',
    '(?i)/bin/(ba)?sh\s+-i\s+[<>]&\s*/dev/(tcp|udp)/',
    '(?i)\snc\s+\S+\s+\d+\s+(-[a-z]+\s+)?-e\s'
)
$scanFiles = Get-ChildItem -LiteralPath $root -Recurse -File -Include *.md, *.ps1, *.sh |
    Where-Object {
        $_.Name -notin @('verify-skill.ps1', 'update-manifest.ps1', 'skill-security-playbook.md') -and
        $_.FullName -notmatch '\\\.git\\'
    }
foreach ($f in $scanFiles) {
    $rel  = $f.FullName.Substring($root.Length + 1) -replace '\\', '/'
    $text = Get-Content -Raw -LiteralPath $f.FullName
    foreach ($p in $patterns) {
        if ($text -match $p) {
            Add-Report $rel 'SUSPICIOUS-PATTERN' ("match: $p")
        }
    }
}

# 4) output
Write-Host "=== 0xNxx-skill verify ===" -ForegroundColor Cyan
Write-Host ("manifest : {0}" -f $manifestPath)
Write-Host ("generated: {0}" -f $manifest.generatedAt)
Write-Host ("files    : {0} in manifest, {1} on disk" -f $known.Count, $onDisk.Count)
Write-Host ""
if ($report.Count -gt 0) {
    foreach ($r in ($report | Sort-Object Type, Path)) {
        $color = 'Yellow'
        if ($r.Type -in @('HASH-MISMATCH', 'UNLISTED', 'HOST-NOT-ALLOWED')) { $color = 'Red' }
        if ($r.Type -eq 'SUSPICIOUS-PATTERN') { $color = 'Magenta' }
        Write-Host ("[{0,-18}] {1}  {2}" -f $r.Type, $r.Path, $r.Detail) -ForegroundColor $color
    }
    Write-Host ""
}

if ($failed) {
    Write-Host "[RESULT] FAIL - ada tanda modifikasi/injeksi. Jangan dipakai sampai diperiksa." -ForegroundColor Red
    Write-Host "         Lihat SECURITY.md & references/skill-security-playbook.md utk langkah berikutnya." -ForegroundColor Yellow
    exit 1
}
Write-Host "[RESULT] PASS - skill utuh sesuai baseline. Gas." -ForegroundColor Green
exit 0