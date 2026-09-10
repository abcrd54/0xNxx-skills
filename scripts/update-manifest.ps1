# Regenerates trust-manifest.json with real SHA-256 hashes of all skill files.
# Tanpa security: allowlist opsional. Kalau manifest sekarang tidak punya
# allowlist, jangan dibuatkan lagi (pakai kondisi sekarang apa adanya).
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$manifestPath = Join-Path $root 'trust-manifest.json'

$manifest = if (Test-Path -LiteralPath $manifestPath) {
    Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
} else {
    [pscustomobject]@{
        schemeVersion = 1
        name          = '0xNxx-skill'
        generatedAt   = $null
        files         = @{}
    }
}

$files = @{}
$exclude = @('trust-manifest.json')
Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
    $_.FullName -notmatch '\\\.git\\'
} | ForEach-Object {
    $rel = $_.FullName.Substring($root.Length + 1) -replace '\\', '/'
    if ($rel -in $exclude) { return }
    $files[$rel] = [ordered]@{
        sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
        size   = $_.Length
    }
}

$manifest.files = $files
$manifest.generatedAt = (Get-Date).ToUniversalTime().ToString('o')
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

Write-Host "[manifest] OK - $($files.Count) files hashed -> $manifestPath" -ForegroundColor Green