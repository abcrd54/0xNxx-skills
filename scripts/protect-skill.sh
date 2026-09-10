#!/bin/bash
# 0xNxx-skill Protector — Encode skill files ke binary format
# Usage: ./protect-skill.sh

set -e

# Configuration
SOURCE_PATH="./core"
OUTPUT_FILE="./skill-data.bin"
XOR_KEY=(79 120 121 78 120 95 48 120 78 120)  # "OxyNx_0xNx"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${CYAN}[*] $1${NC}"; }
success() { echo -e "${GREEN}[+] $1${NC}"; }
error() { echo -e "${RED}[-] $1${NC}"; }

# XOR obfuscation
obfuscate() {
    local data=$1
    local result=""
    local i=0
    
    while IFS= read -r -d '' -n 1 char; do
        local byte=$(printf '%d' "'$char")
        local key_byte=${XOR_KEY[$((i % ${#XOR_KEY[@]}))]}
        local obfuscated=$((byte ^ key_byte))
        result+=$(printf '\\x%02x' $obfuscated)
        ((i++))
    done <<< "$data"
    
    echo -e "$result"
}

# Main
main() {
    echo ""
    echo -e "${CYAN}===========================================${NC}"
    echo -e "${CYAN}     0xNxx-skill Protector${NC}"
    echo -e "${CYAN}===========================================${NC}"
    echo ""
    
    # Find SKILL.md files
    info "Collecting skill files..."
    
    skill_files=$(find "$SOURCE_PATH" -name "SKILL.md" -type f)
    file_count=$(echo "$skill_files" | wc -l)
    
    info "Found $file_count skill files"
    
    # Create temporary binary
    temp_file=$(mktemp)
    
    # Write header
    printf '0xNx' > "$temp_file"
    
    # Write file count
    printf '%04x' $file_count >> "$temp_file"
    
    # Process each file
    while IFS= read -r file; do
        # Get relative path
        relative_path="${file#$SOURCE_PATH/}"
        
        # Encode content
        content=$(cat "$file")
        encoded=$(obfuscate "$content")
        
        # Write to binary
        printf '%04x%s%s' ${#relative_path} "$relative_path" "$encoded" >> "$temp_file"
        
        info "  Encoded: $relative_path"
    done <<< "$skill_files"
    
    # Move to output
    mv "$temp_file" "$OUTPUT_FILE"
    
    success "Protected skill package created: $OUTPUT_FILE"
    success "Size: $(du -h "$OUTPUT_FILE" | cut -f1)"
}

main
