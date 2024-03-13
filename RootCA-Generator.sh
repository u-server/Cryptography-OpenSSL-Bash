#!/bin/bash

# Prompt for certificate details
read -p "Enter Common Name (CN): " commonName
read -p "Enter Organization Name (O): " organizationName
read -p "Enter Organizational Unit Name (OU): " organizationalUnitName
read -p "Enter Email Address: " emailAddress
read -p "Enter Serial Number: " serialNumber

# Generate 4096-bit RSA private key
openssl genpkey -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out priv.key

# Create CSR using prompts for Distinguished Name
openssl req -new -nodes -key priv.key -config <(cat <<-EOF
[ req ]
default_md = sha256
prompt = no
req_extensions = req_ext
distinguished_name = req_distinguished_name
[ req_distinguished_name ]
commonName = $commonName
organizationName = $organizationName
organizationalUnitName = $organizationalUnitName
emailAddress = $emailAddress
serialNumber = $serialNumber
[ req_ext ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
keyUsage=critical,digitalSignature,keyEncipherment,nonRepudiation,dataEncipherment,keyAgreement,keyCertSign,cRLSign
extendedKeyUsage=critical,serverAuth,clientAuth,codeSigning,emailProtection,timeStamping,OCSPSigning,msCodeInd,msCodeCom,msCTLSign,msEFS,ipsecIKE,ipsecEndSystem,ipsecTunnel,ipsecUser
basicConstraints=critical,CA:true
tlsfeature=status_request
EOF
) -nameopt utf8 -utf8 -out cert.csr

# Self-sign CSR with specified validity period, extensions, and version
openssl req -x509 -nodes -in cert.csr -days 36500 -key priv.key -config <(cat <<-EOF
[ req ]
default_md = sha256
prompt = no
req_extensions = req_ext
distinguished_name = req_distinguished_name
[ req_distinguished_name ]
commonName = $commonName
organizationName = $organizationName
organizationalUnitName = $organizationalUnitName
emailAddress = $emailAddress
serialNumber = $serialNumber
[ req_ext ]
keyUsage=critical,digitalSignature,keyEncipherment,nonRepudiation,dataEncipherment,keyAgreement,keyCertSign,cRLSign
extendedKeyUsage=critical,serverAuth,clientAuth,codeSigning,emailProtection,timeStamping,OCSPSigning,msCodeInd,msCodeCom,msCTLSign,msEFS,ipsecIKE,ipsecEndSystem,ipsecTunnel,ipsecUser
basicConstraints=critical,CA:true
tlsfeature=status_request
EOF
) -extensions req_ext -nameopt utf8 -utf8 -out cert.crt -version 3

echo "RootCA Generiert!"
