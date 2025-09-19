# Azure Key Vault Certificate and Key Generator

This script generates all Azure Key Vault supported certificate types and keys for comprehensive testing.

## Usage

### Generate Certificates and Keys
Run the script to generate all certificates and keys:

```bash
./generate_azure_keyvault_certs.sh
```

### Clean Up Generated Files
Run the cleanup script to delete generated certificates and keys:

```bash
./cleanup_certificates.sh
```

**Cleanup Options:**
- **Full cleanup**: Delete all files and directories
- **File cleanup**: Delete files but keep directory structure  
- **Selective cleanup**: Choose specific file types to delete (RSA, EC, symmetric keys, etc.)
- **Targeted cleanup**: Delete only certificates or only keys

### Verify Generated Certificates
Inspect the properties of generated certificates:

```bash
./verify_certificates.sh
```

## Generated Assets

### Key Types Supported by Azure Key Vault

#### RSA Keys
- **RSA-2048**: Most commonly used, good performance vs security balance
- **RSA-3072**: Higher security, moderate performance impact
- **RSA-4096**: Highest security, slower operations

#### Elliptic Curve Keys
- **P-256 (prime256v1)**: Fast, widely supported, good for most use cases
- **P-384 (secp384r1)**: Higher security level, still good performance
- **P-521 (secp521r1)**: Highest EC security, slower than P-256/P-384

#### Symmetric Keys (AES)
- **AES-128**: Fast encryption, suitable for most applications
- **AES-192**: Middle ground security level
- **AES-256**: Highest AES security, government-grade encryption

### Certificate Variations

#### Without SAN (Subject Alternative Names)
- Basic certificates with only CN (Common Name) in subject
- Suitable for simple hostname validation

#### With SAN (Subject Alternative Names)
- Certificates include multiple DNS names and IP addresses
- Required for modern applications and multiple hostname support
- Includes localhost and 127.0.0.1 for testing

### File Formats

#### PEM Format (.pem)
- Text-based format, easy to inspect
- Default format for Linux/Unix systems
- Can be imported directly into Azure Key Vault

#### PKCS#12/PFX Format (.p12)
- Binary format, includes private key and certificate
- Password protected (password: `password123`)
- Native format for Windows, also supported by Azure Key Vault

## Directory Structure After Generation

```
├── rsa_keys/           # RSA private and public key pairs
├── rsa_certs/
│   ├── no_san/         # RSA certificates without SAN extension
│   └── with_san/       # RSA certificates with SAN extension
├── ec_keys/            # Elliptic Curve private and public key pairs
├── ec_certs/
│   ├── no_san/         # EC certificates without SAN extension
│   └── with_san/       # EC certificates with SAN extension
├── symmetric_keys/     # AES symmetric keys (hex and binary formats)
└── pfx_certs/          # Password-protected PKCS#12 certificates
```

## Azure Key Vault Import Notes

### For Certificates:
- Upload `.pem` files to test PEM import functionality
- Upload `.p12` files to test PKCS#12 import functionality
- Password for P12 files: `password123`

### For Keys:
- Private keys from `rsa_keys/` and `ec_keys/` directories
- Symmetric keys from `symmetric_keys/` directory
- Azure Key Vault supports importing existing keys or generating new ones

### For Testing Different Scenarios:
1. **Standard certificates**: Use files from `no_san/` directories
2. **Multi-domain certificates**: Use files from `with_san/` directories  
3. **Key operations**: Use standalone keys from `*_keys/` directories
4. **Certificate operations**: Use certificate files from `*_certs/` directories

## Key Vault Tiers Compatibility

### Standard Tier:
- All generated keys and certificates are supported
- Software-protected keys and certificates

### Premium Tier (HSM):
- All generated keys and certificates are supported
- Hardware Security Module protection
- Same key types, enhanced security

## Certificate Properties

- **Validity**: 365 days from generation
- **Key Usage**: Digital Signature, Key Encipherment, Data Encipherment
- **Extended Key Usage**: Server Authentication, Client Authentication
- **Subject**: Standard organizational fields (US, State, City, etc.)

## Testing Scenarios

Use these generated assets to test:
1. Certificate import/export operations
2. Key import/export operations  
3. Cryptographic operations (sign, verify, encrypt, decrypt)
4. Certificate lifecycle management
5. Key rotation scenarios
6. Different key sizes and algorithms performance
7. HSM vs software key storage

## Security Notes

- All generated keys use secure random generation
- Certificates are self-signed for testing purposes
- Private keys should be treated as sensitive material
- P12 files are password protected for additional security
- For production use, consider proper CA-signed certificates