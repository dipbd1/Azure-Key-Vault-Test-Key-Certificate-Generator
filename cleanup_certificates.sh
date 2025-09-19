#!/bin/bash

# Azure Key Vault Certificate Cleanup Script
# This script safely deletes all generated certificates, keys, and related files
# Includes confirmation prompts to prevent accidental deletion

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to count files in a directory
count_files() {
    local dir=$1
    if [ -d "$dir" ]; then
        find "$dir" -type f | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# Function to display current file count
show_current_files() {
    print_colored $BLUE "=== Current Certificate and Key Inventory ==="
    echo ""
    
    local rsa_keys=$(count_files "rsa_keys")
    local rsa_certs_no_san=$(count_files "rsa_certs/no_san")
    local rsa_certs_with_san=$(count_files "rsa_certs/with_san")
    local ec_keys=$(count_files "ec_keys")
    local ec_certs_no_san=$(count_files "ec_certs/no_san")
    local ec_certs_with_san=$(count_files "ec_certs/with_san")
    local symmetric_keys=$(count_files "symmetric_keys")
    local pfx_certs=$(count_files "pfx_certs")
    
    local total=$((rsa_keys + rsa_certs_no_san + rsa_certs_with_san + ec_keys + ec_certs_no_san + ec_certs_with_san + symmetric_keys + pfx_certs))
    
    echo "📁 RSA Keys:                    $rsa_keys files"
    echo "📁 RSA Certificates (no SAN):  $rsa_certs_no_san files"
    echo "📁 RSA Certificates (SAN):     $rsa_certs_with_san files"
    echo "📁 EC Keys:                     $ec_keys files"
    echo "📁 EC Certificates (no SAN):   $ec_certs_no_san files"
    echo "📁 EC Certificates (SAN):      $ec_certs_with_san files"
    echo "📁 Symmetric Keys:              $symmetric_keys files"
    echo "📁 PKCS#12 Certificates:       $pfx_certs files"
    echo ""
    print_colored $YELLOW "📊 Total files to be deleted: $total"
    echo ""
}

# Function to list files that will be deleted
list_files_to_delete() {
    print_colored $BLUE "=== Files that will be deleted ==="
    echo ""
    
    # Find all certificate and key files
    local files_found=false
    
    for dir in rsa_keys rsa_certs ec_keys ec_certs symmetric_keys pfx_certs; do
        if [ -d "$dir" ]; then
            local count=$(find "$dir" -type f | wc -l | tr -d ' ')
            if [ "$count" -gt 0 ]; then
                print_colored $YELLOW "📂 $dir/ ($count files):"
                find "$dir" -type f -name "*.pem" -o -name "*.p12" -o -name "*.hex" -o -name "*.bin" | sort | sed 's/^/  ├── /'
                echo ""
                files_found=true
            fi
        fi
    done
    
    if [ "$files_found" = false ]; then
        print_colored $GREEN "✅ No certificate or key files found to delete."
        return 1
    fi
    
    return 0
}

# Function to perform cleanup with confirmation
cleanup_with_confirmation() {
    local cleanup_type=$1
    
    case $cleanup_type in
        "all")
            print_colored $RED "⚠️  WARNING: This will delete ALL generated certificates, keys, and directories!"
            echo ""
            echo "This includes:"
            echo "  • All RSA keys and certificates"
            echo "  • All Elliptic Curve keys and certificates" 
            echo "  • All symmetric AES keys"
            echo "  • All PKCS#12 files"
            echo "  • All directory structures"
            echo ""
            read -p "Are you absolutely sure you want to proceed? (type 'DELETE ALL' to confirm): " confirmation
            
            if [ "$confirmation" = "DELETE ALL" ]; then
                perform_full_cleanup
            else
                print_colored $YELLOW "❌ Cleanup cancelled. Invalid confirmation."
                exit 1
            fi
            ;;
            
        "files")
            print_colored $YELLOW "⚠️  This will delete all certificate and key files but keep directory structure."
            echo ""
            read -p "Do you want to continue? (y/N): " -n 1 -r
            echo ""
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                perform_file_cleanup
            else
                print_colored $YELLOW "❌ Cleanup cancelled."
                exit 1
            fi
            ;;
            
        "selective")
            perform_selective_cleanup
            ;;
    esac
}

# Function to perform full cleanup (files + directories)
perform_full_cleanup() {
    print_colored $BLUE "🧹 Starting full cleanup..."
    
    local deleted_count=0
    
    # Remove directories and count files
    for dir in rsa_keys rsa_certs ec_keys ec_certs symmetric_keys pfx_certs; do
        if [ -d "$dir" ]; then
            local count=$(find "$dir" -type f | wc -l | tr -d ' ')
            print_colored $YELLOW "  Removing $dir/ ($count files)..."
            rm -rf "$dir"
            deleted_count=$((deleted_count + count))
        fi
    done
    
    # Clean up any temporary files
    rm -f temp_san_config_*.conf 2>/dev/null || true
    
    print_colored $GREEN "✅ Full cleanup completed!"
    print_colored $GREEN "📊 Deleted $deleted_count files and all directories."
}

# Function to perform file cleanup (keep directories)
perform_file_cleanup() {
    print_colored $BLUE "🧹 Starting file cleanup (keeping directory structure)..."
    
    local deleted_count=0
    
    # Remove files but keep directories
    for dir in rsa_keys rsa_certs ec_keys ec_certs symmetric_keys pfx_certs; do
        if [ -d "$dir" ]; then
            local count=$(find "$dir" -type f | wc -l | tr -d ' ')
            if [ "$count" -gt 0 ]; then
                print_colored $YELLOW "  Cleaning $dir/ ($count files)..."
                find "$dir" -type f -delete
                deleted_count=$((deleted_count + count))
            fi
        fi
    done
    
    # Clean up any temporary files
    rm -f temp_san_config_*.conf 2>/dev/null || true
    
    print_colored $GREEN "✅ File cleanup completed!"
    print_colored $GREEN "📊 Deleted $deleted_count files (directories preserved)."
}

# Function to perform selective cleanup
perform_selective_cleanup() {
    print_colored $BLUE "🎯 Selective Cleanup Mode"
    echo ""
    
    echo "Choose what to delete:"
    echo "1) RSA keys and certificates only"
    echo "2) Elliptic Curve keys and certificates only" 
    echo "3) Symmetric keys only"
    echo "4) PKCS#12 files only"
    echo "5) Certificates only (keep keys)"
    echo "6) Keys only (keep certificates)"
    echo "7) Cancel"
    echo ""
    read -p "Enter your choice (1-7): " choice
    
    case $choice in
        1)
            cleanup_rsa_files
            ;;
        2)
            cleanup_ec_files
            ;;
        3)
            cleanup_symmetric_files
            ;;
        4)
            cleanup_p12_files
            ;;
        5)
            cleanup_certificates_only
            ;;
        6)
            cleanup_keys_only
            ;;
        7)
            print_colored $YELLOW "❌ Cleanup cancelled."
            exit 0
            ;;
        *)
            print_colored $RED "❌ Invalid choice. Cleanup cancelled."
            exit 1
            ;;
    esac
}

# Selective cleanup functions
cleanup_rsa_files() {
    local count=0
    print_colored $YELLOW "🗑️  Deleting RSA keys and certificates..."
    
    if [ -d "rsa_keys" ]; then
        local rsa_count=$(find rsa_keys -type f | wc -l | tr -d ' ')
        rm -rf rsa_keys
        count=$((count + rsa_count))
    fi
    
    if [ -d "rsa_certs" ]; then
        local cert_count=$(find rsa_certs -type f | wc -l | tr -d ' ')
        rm -rf rsa_certs
        count=$((count + cert_count))
    fi
    
    # Remove RSA P12 files
    if [ -d "pfx_certs" ]; then
        local p12_count=$(find pfx_certs -name "rsa_*.p12" | wc -l | tr -d ' ')
        find pfx_certs -name "rsa_*.p12" -delete
        count=$((count + p12_count))
    fi
    
    print_colored $GREEN "✅ Deleted $count RSA-related files."
}

cleanup_ec_files() {
    local count=0
    print_colored $YELLOW "🗑️  Deleting Elliptic Curve keys and certificates..."
    
    if [ -d "ec_keys" ]; then
        local ec_count=$(find ec_keys -type f | wc -l | tr -d ' ')
        rm -rf ec_keys
        count=$((count + ec_count))
    fi
    
    if [ -d "ec_certs" ]; then
        local cert_count=$(find ec_certs -type f | wc -l | tr -d ' ')
        rm -rf ec_certs
        count=$((count + cert_count))
    fi
    
    # Remove EC P12 files
    if [ -d "pfx_certs" ]; then
        local p12_count=$(find pfx_certs -name "ec_*.p12" | wc -l | tr -d ' ')
        find pfx_certs -name "ec_*.p12" -delete
        count=$((count + p12_count))
    fi
    
    print_colored $GREEN "✅ Deleted $count EC-related files."
}

cleanup_symmetric_files() {
    local count=0
    print_colored $YELLOW "🗑️  Deleting symmetric keys..."
    
    if [ -d "symmetric_keys" ]; then
        local sym_count=$(find symmetric_keys -type f | wc -l | tr -d ' ')
        rm -rf symmetric_keys
        count=$((count + sym_count))
    fi
    
    print_colored $GREEN "✅ Deleted $count symmetric key files."
}

cleanup_p12_files() {
    local count=0
    print_colored $YELLOW "🗑️  Deleting PKCS#12 files..."
    
    if [ -d "pfx_certs" ]; then
        local p12_count=$(find pfx_certs -type f | wc -l | tr -d ' ')
        rm -rf pfx_certs
        count=$((count + p12_count))
    fi
    
    print_colored $GREEN "✅ Deleted $count PKCS#12 files."
}

cleanup_certificates_only() {
    local count=0
    print_colored $YELLOW "🗑️  Deleting certificates only (keeping keys)..."
    
    for cert_dir in rsa_certs ec_certs pfx_certs; do
        if [ -d "$cert_dir" ]; then
            local cert_count=$(find "$cert_dir" -type f | wc -l | tr -d ' ')
            rm -rf "$cert_dir"
            count=$((count + cert_count))
        fi
    done
    
    print_colored $GREEN "✅ Deleted $count certificate files (keys preserved)."
}

cleanup_keys_only() {
    local count=0
    print_colored $YELLOW "🗑️  Deleting keys only (keeping certificates)..."
    
    for key_dir in rsa_keys ec_keys symmetric_keys; do
        if [ -d "$key_dir" ]; then
            local key_count=$(find "$key_dir" -type f | wc -l | tr -d ' ')
            rm -rf "$key_dir"
            count=$((count + key_count))
        fi
    done
    
    print_colored $GREEN "✅ Deleted $count key files (certificates preserved)."
}

# Main script execution
print_colored $BLUE "=== Azure Key Vault Certificate Cleanup Tool ==="
echo ""

# Check if we're in the right directory
if [ ! -f "generate_azure_keyvault_certs.sh" ]; then
    print_colored $RED "❌ Error: This script should be run from the certificates directory."
    print_colored $YELLOW "   Make sure you're in the same directory as 'generate_azure_keyvault_certs.sh'"
    exit 1
fi

# Show current inventory
if ! show_current_files; then
    print_colored $GREEN "✅ No certificate or key files found. Nothing to clean up!"
    exit 0
fi

# Check if there are any files to delete
if ! list_files_to_delete; then
    exit 0
fi

# Offer cleanup options
echo ""
print_colored $BLUE "🧹 Cleanup Options:"
echo ""
echo "1) 🗑️  Delete ALL files and directories (complete cleanup)"
echo "2) 📁 Delete files only (keep directory structure)"
echo "3) 🎯 Selective cleanup (choose specific types)"
echo "4) ❌ Cancel cleanup"
echo ""

read -p "Choose cleanup option (1-4): " option

case $option in
    1)
        cleanup_with_confirmation "all"
        ;;
    2)
        cleanup_with_confirmation "files"
        ;;
    3)
        cleanup_with_confirmation "selective"
        ;;
    4)
        print_colored $YELLOW "❌ Cleanup cancelled by user."
        exit 0
        ;;
    *)
        print_colored $RED "❌ Invalid option. Cleanup cancelled."
        exit 1
        ;;
esac

print_colored $GREEN "🎉 Cleanup operation completed successfully!"
echo ""
print_colored $BLUE "💡 Tip: Run './generate_azure_keyvault_certs.sh' to regenerate certificates and keys."