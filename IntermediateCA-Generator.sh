#!/bin/bash

# Create cool design with symbols (output omitted for brevity)
# ...

# Collect user information
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
openssl genpkey -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out intermediate.key

# Create CSR using user-provided information
openssl req -new -nodes -key intermediate.key -config <(cat <<-EOF
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
basicConstraints=critical,CA:true,pathlen:0
# Specify version 3 for the certificate
version = 3
EOF
) -nameopt utf8 -utf8 -out intermediate.csr

# Sign the CSR with the provided root CA files
openssl ca -in intermediate.csr -out intermediate.crt -cert root.crt -keyfile root.key -days 36525 -extensions req_ext -config <(cat <<-EOF
[ ca ]
default_ca = CA_default
[ CA_default ]
default_md = sha256
preserve = no
policy = policy_loose
[ policy_loose ]
# ... (policy fields, omitted for brevity)
# Specify the new_certs_dir (adapt as needed)
new_certs_dir = ./certs
EOF
)

# Export P12 bundle
openssl pkcs12 -export -inkey intermediate.key -in intermediate.crt -out intermediate.p12 -name "C-OSSL-B Intermediate CA Certificate"

echo "Generated files:"
echo "- intermediate.key (private key)"
echo "- intermediate.csr (certificate signing request)"
echo "- intermediate.crt (certificate - version 3)"
echo "- intermediate.p12 (PKCS#12 bundle)"
