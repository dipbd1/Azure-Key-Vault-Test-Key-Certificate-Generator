#!/bin/bash

# Certificate Verification Script
# This script inspects the generated certificates to verify their properties

echo "=== Azure Key Vault Certificate Verification ==="
echo ""

# Function to verify RSA certificates
verify_rsa_cert() {
    local key_size=$1
    local cert_type=$2
    local cert_path=$3
    
    echo "--- RSA-${key_size} Certificate (${cert_type}) ---"
    echo "File: $cert_path"
    
    # Basic certificate info
    openssl x509 -in "$cert_path" -noout -subject -issuer -dates
    
    # Show public key algorithm and size
    echo -n "Public Key: "
    openssl x509 -in "$cert_path" -noout -text | grep "Public Key Algorithm\|Public-Key:"
    
    # Show SAN if present
    if [[ "$cert_type" == "with_san" ]]; then
        echo "Subject Alternative Names:"
        openssl x509 -in "$cert_path" -noout -text | grep -A5 "Subject Alternative Name" || echo "  No SAN found"
    fi
    
    echo ""
}

# Function to verify EC certificates
verify_ec_cert() {
    local curve=$1
    local cert_type=$2
    local cert_path=$3
    
    echo "--- EC-${curve} Certificate (${cert_type}) ---"
    echo "File: $cert_path"
    
    # Basic certificate info
    openssl x509 -in "$cert_path" -noout -subject -issuer -dates
    
    # Show public key algorithm and curve
    echo -n "Public Key: "
    openssl x509 -in "$cert_path" -noout -text | grep "Public Key Algorithm\|ASN1 OID\|NIST CURVE:"
    
    # Show SAN if present
    if [[ "$cert_type" == "with_san" ]]; then
        echo "Subject Alternative Names:"
        openssl x509 -in "$cert_path" -noout -text | grep -A5 "Subject Alternative Name" || echo "  No SAN found"
    fi
    
    echo ""
}

# Function to verify P12 files
verify_p12() {
    local p12_file=$1
    local description=$2
    
    echo "--- PKCS#12 File: $description ---"
    echo "File: $p12_file"
    
    # List contents of P12 file (using password 'password123')
    openssl pkcs12 -in "$p12_file" -nokeys -noout -passin pass:password123 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✓ P12 file is valid and contains certificate"
        openssl pkcs12 -in "$p12_file" -nokeys -passin pass:password123 2>/dev/null | openssl x509 -noout -subject 2>/dev/null
    else
        echo "✗ P12 file verification failed"
    fi
    
    echo ""
}

# Function to show symmetric key info
show_symmetric_key() {
    local key_type=$1
    local hex_file=$2
    local bin_file=$3
    
    echo "--- $key_type Symmetric Key ---"
    echo "Hex file: $hex_file"
    echo "Binary file: $bin_file"
    
    if [ -f "$hex_file" ]; then
        echo -n "Key length (hex): "
        wc -c < "$hex_file" | tr -d ' '
        echo " characters"
        echo -n "First 16 chars: "
        head -c 16 "$hex_file"
        echo ""
    fi
    
    if [ -f "$bin_file" ]; then
        echo -n "Key length (binary): "
        wc -c < "$bin_file" | tr -d ' '
        echo " bytes"
    fi
    
    echo ""
}

echo "1. RSA Certificate Verification"
echo "==============================="

# Verify RSA certificates
for size in 2048 3072 4096; do
    verify_rsa_cert $size "no_san" "rsa_certs/no_san/rsa_${size}_cert_no_san.pem"
    verify_rsa_cert $size "with_san" "rsa_certs/with_san/rsa_${size}_cert_with_san.pem"
done

echo "2. Elliptic Curve Certificate Verification"
echo "=========================================="

# Verify EC certificates
for curve in P256 P384 P521; do
    verify_ec_cert $curve "no_san" "ec_certs/no_san/ec_${curve}_cert_no_san.pem"
    verify_ec_cert $curve "with_san" "ec_certs/with_san/ec_${curve}_cert_with_san.pem"
done

echo "3. PKCS#12 File Verification"
echo "============================"

# Verify P12 files
for size in 2048 3072 4096; do
    verify_p12 "pfx_certs/rsa_${size}_cert.p12" "RSA-${size} (no SAN)"
    verify_p12 "pfx_certs/rsa_${size}_cert_san.p12" "RSA-${size} (with SAN)"
done

for curve in P256 P384 P521; do
    verify_p12 "pfx_certs/ec_${curve}_cert.p12" "EC-${curve} (no SAN)"
    verify_p12 "pfx_certs/ec_${curve}_cert_san.p12" "EC-${curve} (with SAN)"
done

echo "4. Symmetric Key Information"
echo "==========================="

# Show symmetric key info
show_symmetric_key "AES-128" "symmetric_keys/aes_128_key.hex" "symmetric_keys/aes_128_key.bin"
show_symmetric_key "AES-192" "symmetric_keys/aes_192_key.hex" "symmetric_keys/aes_192_key.bin"
show_symmetric_key "AES-256" "symmetric_keys/aes_256_key.hex" "symmetric_keys/aes_256_key.bin"

echo "=== Verification Complete ==="
echo ""
echo "Summary of Generated Assets:"
echo "- 6 RSA key pairs (2048, 3072, 4096 bits - private/public)"
echo "- 6 RSA certificates (3 sizes × 2 variations: with/without SAN)"
echo "- 6 EC key pairs (P256, P384, P521 - private/public)"  
echo "- 6 EC certificates (3 curves × 2 variations: with/without SAN)"
echo "- 12 PKCS#12 files (6 RSA + 6 EC, with/without SAN)"
echo "- 6 AES symmetric keys (3 sizes × 2 formats: hex/binary)"
echo ""
echo "Total: 42 cryptographic assets ready for Azure Key Vault testing"