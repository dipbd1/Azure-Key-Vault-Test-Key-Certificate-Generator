#!/bin/bash

# Azure Key Vault Tools - Main Menu
# This script provides a menu interface for all certificate and key management tools

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print banner
print_banner() {
    print_colored $BLUE "============================================="
    print_colored $BLUE "    Azure Key Vault Certificate Tools"
    print_colored $BLUE "============================================="
    echo ""
    print_colored $CYAN "Complete toolkit for Azure Key Vault testing"
    echo ""
}

# Function to show file count
show_file_count() {
    local total=0
    
    # Count files in each directory
    for dir in rsa_keys rsa_certs ec_keys ec_certs symmetric_keys pfx_certs; do
        if [ -d "$dir" ]; then
            local count=$(find "$dir" -type f | wc -l | tr -d ' ')
            total=$((total + count))
        fi
    done
    
    if [ $total -eq 0 ]; then
        print_colored $YELLOW "📊 Current Status: No certificates or keys generated"
    else
        print_colored $GREEN "📊 Current Status: $total certificate/key files available"
    fi
    echo ""
}

# Main menu function
show_menu() {
    print_colored $BLUE "Available Tools:"
    echo ""
    echo "1️⃣  🔐 Generate Certificates & Keys"
    echo "    Create all Azure Key Vault supported certificates and keys"
    echo "    • RSA (2048, 3072, 4096 bits)"
    echo "    • Elliptic Curve (P-256, P-384, P-521)"
    echo "    • AES Symmetric Keys (128, 192, 256 bits)"
    echo "    • PEM and PKCS#12 formats"
    echo "    • With and without SAN extensions"
    echo ""
    echo "2️⃣  🔍 Verify Certificates"
    echo "    Inspect generated certificate properties"
    echo "    • Certificate details and validity"
    echo "    • Key algorithms and sizes"
    echo "    • Subject Alternative Names"
    echo "    • PKCS#12 file verification"
    echo ""
    echo "3️⃣  🧹 Cleanup Files"
    echo "    Delete generated certificates and keys"
    echo "    • Full cleanup (all files + directories)"
    echo "    • Files only (keep directory structure)"
    echo "    • Selective cleanup (choose file types)"
    echo "    • Targeted cleanup (certs only or keys only)"
    echo ""
    echo "4️⃣  📖 View Documentation"
    echo "    Show comprehensive README documentation"
    echo ""
    echo "5️⃣  ❌ Exit"
    echo ""
}

# Function to execute selected option
execute_option() {
    local choice=$1
    
    case $choice in
        1)
            print_colored $GREEN "🔐 Launching Certificate & Key Generator..."
            echo ""
            ./generate_azure_keyvault_certs.sh
            ;;
        2)
            if [ ! -d "rsa_keys" ] && [ ! -d "ec_keys" ] && [ ! -d "symmetric_keys" ]; then
                print_colored $YELLOW "⚠️  No certificates or keys found to verify."
                print_colored $CYAN "   Run option 1 first to generate certificates and keys."
                return
            fi
            print_colored $GREEN "🔍 Launching Certificate Verifier..."
            echo ""
            ./verify_certificates.sh
            ;;
        3)
            print_colored $GREEN "🧹 Launching Cleanup Tool..."
            echo ""
            ./cleanup_certificates.sh
            ;;
        4)
            print_colored $GREEN "📖 Showing Documentation..."
            echo ""
            if command -v less > /dev/null; then
                less README.md
            elif command -v more > /dev/null; then
                more README.md
            else
                cat README.md
            fi
            ;;
        5)
            print_colored $YELLOW "👋 Goodbye!"
            exit 0
            ;;
        *)
            print_colored $YELLOW "❌ Invalid option. Please choose 1-5."
            ;;
    esac
}

# Main script execution
clear
print_banner
show_file_count

# Interactive mode if no arguments provided
if [ $# -eq 0 ]; then
    while true; do
        show_menu
        read -p "Choose an option (1-5): " choice
        echo ""
        
        execute_option $choice
        
        echo ""
        print_colored $CYAN "Press Enter to continue..."
        read
        clear
        print_banner
        show_file_count
    done
else
    # Direct execution mode with argument
    execute_option $1
fi