#!/bin/bash
# ==============================================
#  0xNxx-skill - Linux Installer
#  Mendukung: Debian/Ubuntu, Kali, Arch
#  Jalankan sebagai root: sudo bash install.sh
# ==============================================

set -e

echo "========================================"
echo "  0xNxx-skill - Linux Tool Installer"
echo "========================================"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    echo "[*] Detected OS: $PRETTY_NAME"
else
    echo "[!!] Cannot detect OS"
    exit 1
fi

# Install base
echo ""
echo "[1/5] Install base dependencies..."

if command -v apt-get &> /dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq \
        python3 python3-pip git curl wget \
        nmap nikto net-tools dnsutils \
        build-essential openssl \
        2>/dev/null
elif command -v dnf &> /dev/null; then
    sudo dnf install -y python3 python3-pip git curl wget nmap nikto 2>/dev/null
elif command -v pacman &> /dev/null; then
    sudo pacman -Sy --noconfirm python python-pip git curl wget nmap nikto 2>/dev/null
else
    echo "Unsupported package manager"
    exit 1
fi

echo "[2/5] Install Python tools..."

# pip tools
pip3 install --upgrade pip 2>/dev/null
pip3 install frida-tools 2>/dev/null
pip3 install pwntools 2>/dev/null
pip3 install sqlmap 2>/dev/null
pip3 install yara-python 2>/dev/null
pip3 install objection 2>/dev/null
pip3 install sublist3r 2>/dev/null

echo "[3/5] Install Go tools..."

if ! command -v go &> /dev/null; then
    echo "    - Installing Go..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y golang 2>/dev/null
    elif command -v pacman &> /dev/null; then
        sudo pacman -Sy --noconfirm go 2>/dev/null
    else
        echo "    [!] Manual install Go: https://golang.org/dl/"
    fi
fi

if command -v go &> /dev/null; then
    export PATH=$PATH:$(go env GOPATH)/bin
    echo "    - Installing nuclei..."
    go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest 2>/dev/null | tail -1
    echo "    - Installing ffuf..."
    go install github.com/ffuf/ffuf/v2@latest 2>/dev/null | tail -1
    echo "    - Installing subfinder..."
    go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest 2>/dev/null | tail -1
    echo "    - Installing httpx..."
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest 2>/dev/null | tail -1
fi

echo "[4/5] Install Android tools..."

if ! command -v adb &> /dev/null; then
    echo "    - Installing adb..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y android-tools-adb android-tools-fastboot 2>/dev/null
    elif command -v pacman &> /dev/null; then
        sudo pacman -Sy --noconfirm android-tools 2>/dev/null
    fi
fi

echo "[5/5] Verify tools..."

# Output tools yang terinstall
echo ""
echo "========================================"
echo "  Output Tools"
echo "========================================"

for cmd in python3 pip3 nmap nikto sqlmap frida adb go nuclei ffuf subfinder httpx; do
    if command -v $cmd &> /dev/null; then
        echo "  [OK] $cmd → $($cmd --version 2>/dev/null | head -1)"
    else
        echo "  [!!] $cmd NOT FOUND"
    fi
done

echo ""
echo "Manual tools perlu install:"
echo "  - Burp Suite: https://portswigger.net/burp"
echo "  - jadx: https://github.com/skylot/jadx/releases"
echo "  - apktool: https://ibotpeaches.github.io/Apktool/install/"
echo "  - Ghidra: https://github.com/NationalSecurityAgency/ghidra/releases"
echo "  - Metasploit: https://www.metasploit.com/download"
echo ""
echo "Install selesai! Restart terminal."
echo ""