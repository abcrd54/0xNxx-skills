<#
.SYNOPSIS
    0xNxx-skill Protector — Encode skill files ke binary format
.DESCRIPTION
    Mengencode semua SKILL.md files ke binary format yang tidak bisa dibaca manual.
    AI agents tetap bisa membaca via loader.
.EXAMPLE
    .\protect-skill.ps1
#>

param(
    [string]$SourcePath = ".\core",
    [string]$OutputFile = ".\skill-data.bin",
    [switch]$Decrypt
)

$ErrorActionPreference = "Stop"

function Write-Status { param([string]$Msg) Write-Host "[*] $Msg" -ForegroundColor Cyan }
function Write-Success { param([string]$Msg) Write-Host "[+] $Msg" -ForegroundColor Green }
function Write-Error { param([string]$Msg) Write-Host "[-] $Msg" -ForegroundColor Red }

# XOR Encryption Key (simple obfuscation)
$XOR_KEY = @(0x4F, 0x78, 0x79, 0x4E, 0x78, 0x5F, 0x30, 0x78, 0x4E, 0x78)

function Obfuscate-Data {
    param([byte[]]$Data)
    
    $result = New-Object byte[] $Data.Length
    for ($i = 0; $i -lt $Data.Length; $i++) {
        $result[$i] = $Data[$i] -bxor $XOR_KEY[$i % $XOR_KEY.Length]
    }
    return $result
}

function Protect-Skill {
    param(
        [string]$Source,
        [string]$Output
    )
    
    Write-Status "Collecting skill files..."
    
    # Find all SKILL.md files
    $skillFiles = Get-ChildItem -Path $Source -Filter "SKILL.md" -Recurse
    
    Write-Status "Found $($skillFiles.Count) skill files"
    
    # Build data structure
    $data = @{}
    
    foreach ($file in $skillFiles) {
        $relativePath = $file.FullName.Replace((Resolve-Path $Source).Path, "").TrimStart("\", "/")
        $content = Get-Content -Path $file.FullName -Raw
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
        $obfuscated = Obfuscate-Data -Data $bytes
        $data[$relativePath] = $obfuscated
        
        Write-Status "  Encoded: $relativePath"
    }
    
    # Serialize to binary
    Write-Status "Creating binary package..."
    
    $memoryStream = New-Object System.IO.MemoryStream
    $writer = New-Object System.IO.BinaryWriter($memoryStream)
    
    # Write magic header
    $writer.Write([byte[]]@(0x30, 0x78, 0x4E, 0x78))  # "0xNx"
    
    # Write file count
    $writer.Write([int32]$data.Count)
    
    # Write each file
    foreach ($key in $data.Keys) {
        $pathBytes = [System.Text.Encoding]::UTF8.GetBytes($key)
        $writer.Write([int32]$pathBytes.Length)
        $writer.Write($pathBytes)
        $writer.Write([int32]$data[$key].Length)
        $writer.Write($data[$key])
    }
    
    $writer.Flush()
    $binaryData = $memoryStream.ToArray()
    
    # Write to file
    [System.IO.File]::WriteAllBytes($Output, $binaryData)
    
    Write-Success "Protected skill package created: $Output"
    Write-Success "Size: $([math]::Round($binaryData.Length / 1KB, 2)) KB"
}

function Unprotect-Skill {
    param(
        [string]$InputFile,
        [string]$OutputPath
    )
    
    Write-Status "Reading protected package..."
    
    $binaryData = [System.IO.File]::ReadAllBytes($InputFile)
    $reader = New-Object System.IO.BinaryReader([System.IO.MemoryStream]::new($binaryData))
    
    # Read header
    $header = $reader.ReadBytes(4)
    if ([System.Text.Encoding]::UTF8.GetString($header) -ne "0xNx") {
        Write-Error "Invalid file format"
        return
    }
    
    # Read file count
    $fileCount = $reader.ReadInt32()
    Write-Status "Package contains $fileCount files"
    
    # Read each file
    for ($i = 0; $i -lt $fileCount; $i++) {
        $pathLen = $reader.ReadInt32()
        $pathBytes = $reader.ReadBytes($pathLen)
        $relativePath = [System.Text.Encoding]::UTF8.GetString($pathBytes)
        
        $dataLen = $reader.ReadInt32()
        $data = $reader.ReadBytes($dataLen)
        
        # Deobfuscate
        $deobfuscated = Obfuscate-Data -Data $data
        $content = [System.Text.Encoding]::UTF8.GetString($deobfuscated)
        
        # Write file
        $outputFile = Join-Path $OutputPath $relativePath
        $outputDir = Split-Path $outputFile -Parent
        
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        Set-Content -Path $outputFile -Value $content -NoNewline
        Write-Status "  Decoded: $relativePath"
    }
    
    Write-Success "All files decoded to: $OutputPath"
}

# Main
if ($Decrypt) {
    if (-not (Test-Path $OutputFile)) {
        Write-Error "File not found: $OutputFile"
        exit 1
    }
    Unprotect-Skill -InputFile $OutputFile -OutputPath ".\core-decoded"
}
else {
    if (-not (Test-Path $SourcePath)) {
        Write-Error "Source path not found: $SourcePath"
        exit 1
    }
    Protect-Skill -Source $SourcePath -Output $OutputFile
}
