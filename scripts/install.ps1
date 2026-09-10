# PowerShell Installer untuk 0xNxx-skill

# Skrip ini menginstal tool dasar untuk keamanan siber di Windows.
# Jalankan dengan PowerShell ADMIN: 
#    powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  0xNxx-skill - Windows Tool Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Cek apakah ada Winget
function Test-Winget {
    try {
        $null = winget --version
        return $true
    } catch {
        return $false
    }
}

# Cek apakah ada Chocolatey
function Test-Choco {
    try {
        $null = choco --version
        return $true
    } catch {
        return $false
    }
}

Write-Host "[1/6] Memeriksa Package Manager..." -ForegroundColor Yellow

$choco = Test-Choco
$winget = Test-Winget

if (-not $choco -and -not $winget) {
    Write-Host "[!] Tidak ada Winget atau Chocolatey. Install Chocolatey dulu:" -ForegroundColor Red
    Write-Host "    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    exit 1
}

Write-Host "    Winget: $winget | Choco: $choco" -ForegroundColor Green

# Helper install function
function Install-WithFallback {
    param([string]$Name, [string]$WingetId, [string]$ChocoId)
    
    Write-Host "    - Menginstall $Name..." -ForegroundColor Yellow
    try {
        if ($winget) {
            winget install --id $WingetId --silent --accept-package-agreements --accept-source-agreements 2>$null
        }
    } catch {
        Write-Host "    - Winget gagal, coba Chocolatey..." -ForegroundColor DarkYellow
    }
    
    if (-not $choco) { return }
    try {
        choco install $ChocoId -y 2>$null
    } catch {
        Write-Host "    - Install $Name gagal. Manual install..." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "[2/6] Install Tools Dasar..." -ForegroundColor Yellow

# Tools harus diinstall:
# - Python (untuk pip tools: frida, pwntools)
# - Git (untuk clone repo)
# - Node.js (untuk beberapa tools web)

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "    - Python tidak ada, install..." -ForegroundColor Yellow
    if ($winget) { winget install Python.Python.3.11 --silent }
    elseif ($choco) { choco install python3 -y }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "    - Git tidak ada, install..." -ForegroundColor Yellow
    if ($winget) { winget install Git.Git --silent }
    elseif ($choco) { choco install git -y }
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "    - Node.js tidak ada, install..." -ForegroundColor Yellow
    if ($winget) { winget install OpenJS.NodeJS.LTS --silent }
    elseif ($choco) { choco install nodejs-lts -y }
}

Write-Host ""
Write-Host "[3/6] Install Tools via Python (pip)..." -ForegroundColor Yellow

$pip_tools = @(
    @{ Name = "frida-tools"; Command = "frida" },
    @{ Name = "pwntools"; Command = "pwn" },
    @{ Name = "sqlmap"; Command = "sqlmap" },
    @{ Name = "yara-python"; Command = "yara" }
)

foreach ($tool in $pip_tools) {
    if (-not (Get-Command $tool.Command -ErrorAction SilentlyContinue)) {
        Write-Host "    - Install $($tool.Name)..." -ForegroundColor Yellow
        pip install $tool.Name 2>$null
    }
}

Write-Host ""
Write-Host "[4/6] Install Tools via Package Manager..." -ForegroundColor Yellow

# Tools OS-level
if (-not (Get-Command nmap -ErrorAction SilentlyContinue)) {
    Write-Host "    - Install nmap..." -ForegroundColor Yellow
    if ($winget) { winget install Insecure.Nmap --silent }
    elseif ($choco) { choco install nmap -y }
}

if (-not (Get-Command nikto -ErrorAction SilentlyContinue)) {
    Write-Host "    - Install nikto..." -ForegroundColor Yellow
    if ($winget) { winget install Cimon.Perl --silent } # Perl dependency
    elseif ($choco) { choco install nikto -y }
}

Write-Host ""
Write-Host "[5/6] Install Mobile & RE Tools..." -ForegroundColor Yellow

# Android
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Write-Host "    - Install adb (Android Platform-Tools)..." -ForegroundColor Yellow
    if ($winget) { winget install Google.PlatformTools --silent }
    elseif ($choco) { choco install android-sdk -y }
}

# Java (untuk apktool, jadx)
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "    - Install Java JDK..." -ForegroundColor Yellow
    if ($winget) { winget install Microsoft.OpenJDK.11 --silent }
    elseif ($choco) { choco install openjdk11 -y }
}

Write-Host ""
Write-Host "[6/6] Tampilkan Path Tools..." -ForegroundColor Yellow

# Verifikasi hasil
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Output Tools yang Terinstall" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$tools_to_check = @("python", "git", "node", "pip", "nmap", "adb", "java", "frida", "sqlmap", "pwn")
foreach ($name in $tools_to_check) {
    if (Get-Command $name -ErrorAction SilentlyContinue) {
        $version = & $name --version 2>$null | Select-Object -First 1
        Write-Host "  [OK] $name → $version" -ForegroundColor Green
    } else {
        Write-Host "  [!!] $name belum terinstall" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Tools yang perlu manual:" -ForegroundColor Yellow
Write-Host "  - Burp Suite Community: https://portswigger.net/burp"
Write-Host "  - jadx (Java decompiler): https://github.com/skylot/jadx/releases"
Write-Host "  - apktool: https://ibotpeaches.github.io/Apktool/install/"
Write-Host "  - Ghidra: https://github.com/NationalSecurityAgency/ghidra/releases"
Write-Host ""
Write-Host "Selesai! Restart terminal untuk refresh PATH." -ForegroundColor Green