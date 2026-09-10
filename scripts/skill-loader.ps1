<#
.SYNOPSIS
    0xNxx-skill Loader — Decode protected skill files untuk AI agents
.DESCRIPTION
    Load skill files dari binary format untuk digunakan oleh AI agents.
    Menyediakan routing dan akses ke semua module.
.EXAMPLE
    .\skill-loader.ps1 "pentest-web" "scan website for vulnerabilities"
#>

param(
    [string]$Module = "",
    [string]$Task = "",
    [switch]$List,
    [switch]$Interactive
)

$ErrorActionPreference = "Stop"

# Configuration
$SKILL_PACKAGE = Join-Path $PSScriptRoot "..\skill-data.bin"
$XOR_KEY = @(0x4F, 0x78, 0x79, 0x4E, 0x78, 0x5F, 0x30, 0x78, 0x4E, 0x78)

# Module Registry
$MODULE_REGISTRY = @{
    "pentest-web" = "core/pentest-web/SKILL.md"
    "reverse-binary" = "core/reverse-binary/SKILL.md"
    "mobile-android" = "core/mobile-android/SKILL.md"
    "mobile-ios" = "core/mobile-ios/SKILL.md"
    "malware-analysis" = "core/malware-analysis/SKILL.md"
    "network-recon" = "core/network-recon/SKILL.md"
    "exploit-dev" = "core/exploit-dev/SKILL.md"
    "crypto" = "core/crypto/SKILL.md"
    "forensics" = "core/forensics/SKILL.md"
    "wifi-pentest" = "core/wifi-pentest/SKILL.md"
    "active-directory" = "core/active-directory/SKILL.md"
    "container-escape" = "core/container-escape/SKILL.md"
    "mitm-network" = "core/mitm-network/SKILL.md"
    "wordpress-exploit" = "core/wordpress-exploit/SKILL.md"
    "edr-bypass" = "core/edr-bypass/SKILL.md"
    "malware-dev" = "core/malware-dev/SKILL.md"
    "game-hacking" = "core/game-hacking/SKILL.md"
    "redteam-c2" = "core/redteam-c2/SKILL.md"
    "breach-workflows" = "core/breach-workflows/SKILL.md"
}

# Keyword Routing
$KEYWORD_ROUTING = @{
    # Web Pentest
    "sql" = "pentest-web"
    "sqli" = "pentest-web"
    "xss" = "pentest-web"
    "ssrf" = "pentest-web"
    "ssti" = "pentest-web"
    "idor" = "pentest-web"
    "jwt" = "pentest-web"
    "web" = "pentest-web"
    "website" = "pentest-web"
    "burp" = "pentest-web"
    
    # Binary RE
    "binary" = "reverse-binary"
    "reverse" = "reverse-binary"
    "decompile" = "reverse-binary"
    "ghidra" = "reverse-binary"
    "radare" = "reverse-binary"
    
    # Mobile
    "apk" = "mobile-android"
    "android" = "mobile-android"
    "frida" = "mobile-android"
    "ssl pinning" = "mobile-android"
    "ipa" = "mobile-ios"
    "ios" = "mobile-ios"
    "keychain" = "mobile-ios"
    
    # Malware
    "malware" = "malware-analysis"
    "virus" = "malware-analysis"
    "yara" = "malware-analysis"
    "rat" = "malware-analysis"
    
    # Network
    "nmap" = "network-recon"
    "port" = "network-recon"
    "scan" = "network-recon"
    "subdomain" = "network-recon"
    "recon" = "network-recon"
    
    # Exploit
    "exploit" = "exploit-dev"
    "pwn" = "exploit-dev"
    "buffer overflow" = "exploit-dev"
    "rop" = "exploit-dev"
    "privesc" = "exploit-dev"
    
    # Crypto
    "crypto" = "crypto"
    "encrypt" = "crypto"
    "decrypt" = "crypto"
    "hash" = "crypto"
    "rsa" = "crypto"
    "xor" = "crypto"
    
    # Forensics
    "forensic" = "forensics"
    "dfir" = "forensics"
    "pcap" = "forensics"
    "memory dump" = "forensics"
    "stego" = "forensics"
    
    # WiFi
    "wifi" = "wifi-pentest"
    "wpa" = "wifi-pentest"
    "handshake" = "wifi-pentest"
    
    # AD
    "active directory" = "active-directory"
    "kerberos" = "active-directory"
    "dcsync" = "active-directory"
    "domain" = "active-directory"
    
    # Container
    "docker" = "container-escape"
    "kubernetes" = "container-escape"
    "container" = "container-escape"
    
    # MITM
    "mitm" = "mitm-network"
    "arp spoof" = "mitm-network"
    "dns spoof" = "mitm-network"
    
    # WordPress
    "wordpress" = "wordpress-exploit"
    "wp" = "wordpress-exploit"
    
    # EDR
    "edr" = "edr-bypass"
    "antivirus" = "edr-bypass"
    "bypass" = "edr-bypass"
    
    # Malware Dev
    "malware dev" = "malware-dev"
    "implant" = "malware-dev"
    "backdoor" = "malware-dev"
    "shellcode" = "malware-dev"
    
    # Game
    "game" = "game-hacking"
    "cheat" = "game-hacking"
    "aimbot" = "game-hacking"
    
    # Red Team
    "red team" = "redteam-c2"
    "c2" = "redteam-c2"
    "command and control" = "redteam-c2"
    
    # Breach
    "breach" = "breach-workflows"
    "kill chain" = "breach-workflows"
    "attack chain" = "breach-workflows"
}

function Deobfuscate-Data {
    param([byte[]]$Data)
    
    $result = New-Object byte[] $Data.Length
    for ($i = 0; $i -lt $Data.Length; $i++) {
        $result[$i] = $Data[$i] -bxor $XOR_KEY[$i % $XOR_KEY.Length]
    }
    return $result
}

function Load-SkillPackage {
    if (-not (Test-Path $SKILL_PACKAGE)) {
        Write-Host "[-] Skill package not found. Run protect-skill.ps1 first." -ForegroundColor Red
        return $null
    }
    
    $binaryData = [System.IO.File]::ReadAllBytes($SKILL_PACKAGE)
    $reader = New-Object System.IO.BinaryReader([System.IO.MemoryStream]::new($binaryData))
    
    # Read header
    $header = $reader.ReadBytes(4)
    if ([System.Text.Encoding]::UTF8.GetString($header) -ne "0xNx") {
        Write-Host "[-] Invalid skill package format." -ForegroundColor Red
        return $null
    }
    
    # Read file count
    $fileCount = $reader.ReadInt32()
    
    # Read files
    $files = @{}
    for ($i = 0; $i -lt $fileCount; $i++) {
        $pathLen = $reader.ReadInt32()
        $pathBytes = $reader.ReadBytes($pathLen)
        $relativePath = [System.Text.Encoding]::UTF8.GetString($pathBytes)
        
        $dataLen = $reader.ReadInt32()
        $data = $reader.ReadBytes($dataLen)
        
        $deobfuscated = Deobfuscate-Data -Data $data
        $content = [System.Text.Encoding]::UTF8.GetString($deobfuscated)
        
        $files[$relativePath] = $content
    }
    
    return $files
}

function Route-Task {
    param([string]$TaskText)
    
    $taskLower = $TaskText.ToLower()
    
    foreach ($keyword in $KEYWORD_ROUTING.Keys) {
        if ($taskLower -match $keyword) {
            return $KEYWORD_ROUTING[$keyword]
        }
    }
    
    return "pentest-web"  # Default
}

function Get-SkillContent {
    param(
        [hashtable]$Files,
        [string]$Module
    )
    
    $path = $MODULE_REGISTRY[$Module]
    if ($path -and $Files.ContainsKey($path)) {
        return $Files[$path]
    }
    
    return $null
}

# Main
if ($List) {
    Write-Host "`nAvailable Modules:" -ForegroundColor Cyan
    Write-Host "=" * 50
    foreach ($key in ($MODULE_REGISTRY.Keys | Sort-Object)) {
        Write-Host "  $key" -ForegroundColor Green
    }
    Write-Host ""
    return
}

if ($Interactive) {
    Write-Host "`n0xNxx-skill Interactive Mode" -ForegroundColor Cyan
    Write-Host "=" * 50
    Write-Host "Type 'exit' to quit, 'list' to see modules`n"
    
    $files = Load-SkillPackage
    if (-not $files) { return }
    
    while ($true) {
        $input = Read-Host "Task"
        if ($input -eq "exit") { break }
        if ($input -eq "list") {
            foreach ($key in ($MODULE_REGISTRY.Keys | Sort-Object)) {
                Write-Host "  $key" -ForegroundColor Green
            }
            continue
        }
        
        $module = Route-Task -TaskText $input
        $content = Get-SkillContent -Files $files -Module $module
        
        if ($content) {
            Write-Host "`n[Module: $module]`n" -ForegroundColor Yellow
            Write-Host $content
        }
        else {
            Write-Host "[-] Module not found: $module" -ForegroundColor Red
        }
    }
}
elseif ($Module -or $Task) {
    $files = Load-SkillPackage
    if (-not $files) { return }
    
    if (-not $Module -and $Task) {
        $Module = Route-Task -TaskText $Task
    }
    
    $content = Get-SkillContent -Files $files -Module $Module
    
    if ($content) {
        Write-Host $content
    }
    else {
        Write-Host "[-] Module not found: $Module" -ForegroundColor Red
    }
}
