#!/bin/bash
# 0xNxx-skill One-Line Installer for Linux/macOS/Termux
# Usage: curl -sSL https://raw.githubusercontent.com/bengt-skill/0xNxx-skill/main/install.sh | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
REPO_URL="https://github.com/bengt-skill/0xNxx-skill/archive/refs/heads/main.zip"
TEMP_DIR="/tmp/0xnxx-install"

# Functions
info() { echo -e "${CYAN}[*] $1${NC}"; }
success() { echo -e "${GREEN}[+] $1${NC}"; }
error() { echo -e "${RED}[-] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }

# Detect Agent
detect_agent() {
    if [ -d "$HOME/.config/opencode/skills" ]; then
        echo "OpenCode"
    elif [ -d "$HOME/.claude/skills" ]; then
        echo "Claude"
    else
        echo "OpenCode"
    fi
}

# Get Install Path
get_install_path() {
    local agent=$1
    case $agent in
        "OpenCode") echo "$HOME/.config/opencode/skills/0xNxx-skill" ;;
        "Claude") echo "$HOME/.claude/skills/0xNxx-skill" ;;
        *) echo "$HOME/.config/opencode/skills/0xNxx-skill" ;;
    esac
}

# Install
install_skill() {
    local target_path=$1
    
    info "Downloading 0xNxx-skill..."
    
    # Create temp dir
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    # Download
    if command -v curl &> /dev/null; then
        curl -sSL -o "$TEMP_DIR/0xnxx-skill.zip" "$REPO_URL"
    elif command -v wget &> /dev/null; then
        wget -q -O "$TEMP_DIR/0xnxx-skill.zip" "$REPO_URL"
    else
        error "Neither curl nor wget found"
        exit 1
    fi
    
    info "Extracting files..."
    
    # Extract
    unzip -q -o "$TEMP_DIR/0xnxx-skill.zip" -d "$TEMP_DIR"
    
    # Move to target
    source_dir=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "0xNxx-skill-*" | head -1)
    
    if [ -d "$target_path" ]; then
        warn "Existing installation found, removing..."
        rm -rf "$target_path"
    fi
    
    mv "$source_dir" "$target_path"
    
    # Cleanup
    rm -rf "$TEMP_DIR"
}

# Main
main() {
    echo ""
    echo -e "${CYAN}===========================================${NC}"
    echo -e "${CYAN}     0xNxx-skill Installer v2.0${NC}"
    echo -e "${CYAN}===========================================${NC}"
    echo ""
    
    # Detect agent
    agent=$(detect_agent)
    info "Detected agent: $agent"
    
    # Get install path
    install_path=$(get_install_path "$agent")
    info "Install path: $install_path"
    
    # Check existing
    if [ -d "$install_path" ]; then
        warn "Already installed at: $install_path"
        read -p "Reinstall? (y/N): " response
        if [ "$response" != "y" ]; then
            info "Installation cancelled"
            exit 0
        fi
        rm -rf "$install_path"
    fi
    
    # Install
    install_skill "$install_path"
    
    success "Installation complete!"
    echo ""
    echo -e "${GREEN}Installed to: $install_path${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  1. Open your AI agent"
    echo "  2. Type tasks in Bahasa Indonesia"
    echo "  3. Agent will auto-route to correct module"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo '  "Scan website https://example.com for vulnerabilities"'
    echo '  "Analyze this binary and find the password"'
    echo '  "Bypass SSL pinning on this APK"'
}

main
