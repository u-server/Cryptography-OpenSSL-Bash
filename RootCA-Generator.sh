#!/bin/bash

clear

# Create cool design with symbols
echo "      _ _   _  _   _  _     _ _ "
echo "     | | | ( )(_| | | | |   | | |"
echo "     | |_| |/ / _ \ |_| |__ | | |"
echo "     | __|    | (_) | __| '_ \| | |"
echo "     |_|     |_|\___|_| |_.__/|_| |"

echo -n "Enter commonName: "
read commonName
echo -n "Enter organizationName: "
read organizationName
echo -n "Enter organizationalUnitName: "
read organizationalUnitName
echo -n "Enter emailAddress: "
read emailAddress
echo -n "Enter serialNumber: "
read serialNumber

# Generate 4096-bit RSA private key
openssl genpkey -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out root.key

# Create CSR using user-provided information
openssl req -new -nodes -key root.key -config <(cat <<-EOF
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
) -nameopt utf8 -utf8 -out root.csr

# Self-sign the CSR with 100-year validity and version 3
openssl req -x509 -nodes -in root.csr -days 36525 -key root.key -config <(cat <<-EOF
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
) -extensions req_ext -nameopt utf8 -utf8 -out root.crt

# Export private key and certificate to P12 file
openssl pkcs12 -export -inkey root.key -in root.crt -out root.p12 -name "C-OSSL-B CA Certificate"

echo "Generated files:"
echo "- root.key (private key)"
echo "- root.csr (certificate signing request)"
echo "- root.crt (certificate)"
echo "- root.p12 (PKCS#12 bundle)"
