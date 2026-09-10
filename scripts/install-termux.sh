#!/bin/bash
# ==============================================
#  0xNxx-skill - Termux Installer (Android)
#  Jalankan di Termux: bash install-termux.sh
# ==============================================

set -e

echo "========================================"
echo "  0xNxx-skill - Termux Installer"
echo "========================================"

# Update packages
echo "[1/4] Update Termux packages..."
pkg update -y
pkg upgrade -y

# Install base
echo "[2/4] Install base dependencies..."
pkg install -y \
    python python-pip git curl wget \
    nmap openssl \
    openjdk-17 \
    binutils \
    2>/dev/null

# Python tools
echo "[3/4] Install Python tools..."
pip install --upgrade pip 2>/dev/null
pip install frida-tools 2>/dev/null
pip install sqlmap 2>/dev/null
pip install yara-python 2>/dev/null

# Verifikasi
echo "[4/4] Verify..."
echo ""
echo "========================================"
echo "  Output Tools"
echo "========================================"

for cmd in python nmap git curl java pip; do
    if command -v $cmd &> /dev/null; then
        echo "  [OK] $cmd → $($cmd --version 2>/dev/null | head -1)"
    else
        echo "  [!!] $cmd NOT FOUND"
    fi
done

echo ""
echo "Catatan:"
echo "  - frida untuk Android native hooking harus di-install di device (root/jailbreak)"
echo "  - Termux tidak bisa install Ghidra/IDA (butuh GUI besar)"
echo "  - Untuk deep reverse, sebaiknya pindah ke desktop"
echo ""