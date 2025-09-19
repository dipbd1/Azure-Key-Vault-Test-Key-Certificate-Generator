#!/bin/bash

# Azure Key Vault Certificate and Key Generation Script
# This script generates all supported key types and certificates for Azure Key Vault testing
# Supports RSA (2048, 3072, 4096) and EC (P-256, P-384, P-521) algorithms

set -e

# Create output directories
mkdir -p rsa_keys rsa_certs ec_keys ec_certs symmetric_keys pfx_certs
mkdir -p rsa_certs/no_san rsa_certs/with_san ec_certs/no_san ec_certs/with_san

echo "=== Azure Key Vault Certificate and Key Generation ==="
echo "Generating keys and certificates for Azure Key Vault testing..."
echo ""

# Function to generate RSA keys and certificates
generate_rsa() {
    local key_size=$1
    echo "Generating RSA-${key_size} key and certificates..."
    
    # Generate RSA private key
    openssl genrsa -out "rsa_keys/rsa_${key_size}_private.pem" $key_size
    
    # Extract public key
    openssl rsa -in "rsa_keys/rsa_${key_size}_private.pem" -pubout -out "rsa_keys/rsa_${key_size}_public.pem"
    
    # Generate self-signed certificate WITHOUT SAN
    openssl req -new -x509 -key "rsa_keys/rsa_${key_size}_private.pem" \
        -out "rsa_certs/no_san/rsa_${key_size}_cert_no_san.pem" \
        -days 365 \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=test-rsa-${key_size}.example.com"
    
    # Create config file for certificate with SAN
    cat > "temp_san_config_rsa_${key_size}.conf" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = State
L = City
O = Organization
OU = Unit
CN = test-rsa-${key_size}-san.example.com

[v3_req]
keyUsage = keyEncipherment, dataEncipherment, digitalSignature
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = test-rsa-${key_size}-san.example.com
DNS.2 = alt-rsa-${key_size}.example.com
DNS.3 = localhost
IP.1 = 127.0.0.1
EOF
    
    # Generate self-signed certificate WITH SAN
    openssl req -new -x509 -key "rsa_keys/rsa_${key_size}_private.pem" \
        -out "rsa_certs/with_san/rsa_${key_size}_cert_with_san.pem" \
        -days 365 \
        -config "temp_san_config_rsa_${key_size}.conf" \
        -extensions v3_req
    
    # Generate PKCS#12 format (PFX)
    openssl pkcs12 -export -out "pfx_certs/rsa_${key_size}_cert.p12" \
        -inkey "rsa_keys/rsa_${key_size}_private.pem" \
        -in "rsa_certs/no_san/rsa_${key_size}_cert_no_san.pem" \
        -passout pass:password123
    
    # Generate PKCS#12 with SAN
    openssl pkcs12 -export -out "pfx_certs/rsa_${key_size}_cert_san.p12" \
        -inkey "rsa_keys/rsa_${key_size}_private.pem" \
        -in "rsa_certs/with_san/rsa_${key_size}_cert_with_san.pem" \
        -passout pass:password123
    
    # Cleanup temp config
    rm "temp_san_config_rsa_${key_size}.conf"
    
    echo "  ✓ RSA-${key_size} keys and certificates generated"
}

# Function to generate EC keys and certificates
generate_ec() {
    local curve=$1
    local curve_name=$2
    echo "Generating EC-${curve_name} key and certificates..."
    
    # Generate EC private key
    openssl ecparam -genkey -name $curve -out "ec_keys/ec_${curve_name}_private.pem"
    
    # Extract public key
    openssl ec -in "ec_keys/ec_${curve_name}_private.pem" -pubout -out "ec_keys/ec_${curve_name}_public.pem"
    
    # Generate self-signed certificate WITHOUT SAN
    openssl req -new -x509 -key "ec_keys/ec_${curve_name}_private.pem" \
        -out "ec_certs/no_san/ec_${curve_name}_cert_no_san.pem" \
        -days 365 \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=test-ec-${curve_name}.example.com"
    
    # Create config file for certificate with SAN
    cat > "temp_san_config_ec_${curve_name}.conf" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = State
L = City
O = Organization
OU = Unit
CN = test-ec-${curve_name}-san.example.com

[v3_req]
keyUsage = keyEncipherment, dataEncipherment, digitalSignature
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = test-ec-${curve_name}-san.example.com
DNS.2 = alt-ec-${curve_name}.example.com
DNS.3 = localhost
IP.1 = 127.0.0.1
EOF
    
    # Generate self-signed certificate WITH SAN
    openssl req -new -x509 -key "ec_keys/ec_${curve_name}_private.pem" \
        -out "ec_certs/with_san/ec_${curve_name}_cert_with_san.pem" \
        -days 365 \
        -config "temp_san_config_ec_${curve_name}.conf" \
        -extensions v3_req
    
    # Generate PKCS#12 format (PFX)
    openssl pkcs12 -export -out "pfx_certs/ec_${curve_name}_cert.p12" \
        -inkey "ec_keys/ec_${curve_name}_private.pem" \
        -in "ec_certs/no_san/ec_${curve_name}_cert_no_san.pem" \
        -passout pass:password123
    
    # Generate PKCS#12 with SAN
    openssl pkcs12 -export -out "pfx_certs/ec_${curve_name}_cert_san.p12" \
        -inkey "ec_keys/ec_${curve_name}_private.pem" \
        -in "ec_certs/with_san/ec_${curve_name}_cert_with_san.pem" \
        -passout pass:password123
    
    # Cleanup temp config
    rm "temp_san_config_ec_${curve_name}.conf"
    
    echo "  ✓ EC-${curve_name} keys and certificates generated"
}

# Function to generate symmetric keys (for Azure Key Vault key operations)
generate_symmetric_keys() {
    echo "Generating symmetric keys..."
    
    # AES-128
    openssl rand -hex 16 > symmetric_keys/aes_128_key.hex
    openssl rand 16 > symmetric_keys/aes_128_key.bin
    
    # AES-192
    openssl rand -hex 24 > symmetric_keys/aes_192_key.hex
    openssl rand 24 > symmetric_keys/aes_192_key.bin
    
    # AES-256
    openssl rand -hex 32 > symmetric_keys/aes_256_key.hex
    openssl rand 32 > symmetric_keys/aes_256_key.bin
    
    echo "  ✓ Symmetric keys (AES-128, AES-192, AES-256) generated"
}

# Generate RSA keys and certificates (Azure Key Vault supported sizes)
echo "1. Generating RSA keys and certificates..."
generate_rsa 2048
generate_rsa 3072
generate_rsa 4096

echo ""
echo "2. Generating Elliptic Curve keys and certificates..."
# Generate EC keys and certificates (Azure Key Vault supported curves)
generate_ec "prime256v1" "P256"  # P-256
generate_ec "secp384r1" "P384"   # P-384
generate_ec "secp521r1" "P521"   # P-521

echo ""
echo "3. Generating symmetric keys..."
generate_symmetric_keys

echo ""
echo "=== Generation Complete ==="
echo ""
echo "Generated files structure:"
echo "├── rsa_keys/           - RSA private and public keys"
echo "├── rsa_certs/"
echo "│   ├── no_san/         - RSA certificates without SAN"
echo "│   └── with_san/       - RSA certificates with SAN"
echo "├── ec_keys/            - Elliptic Curve private and public keys"
echo "├── ec_certs/"
echo "│   ├── no_san/         - EC certificates without SAN"
echo "│   └── with_san/       - EC certificates with SAN"
echo "├── symmetric_keys/     - AES symmetric keys (hex and binary)"
echo "└── pfx_certs/          - PKCS#12/PFX certificates (password: password123)"
echo ""
echo "Key Types Generated:"
echo "- RSA: 2048, 3072, 4096 bits"
echo "- Elliptic Curve: P-256, P-384, P-521"
echo "- AES Symmetric: 128, 192, 256 bits"
echo ""
echo "Certificate Formats:"
echo "- PEM format (.pem)"
echo "- PKCS#12 format (.p12) - password protected"
echo "- With and without Subject Alternative Names (SAN)"
echo ""
echo "All files are ready for Azure Key Vault upload and testing!"