#!/bin/bash

clear

# Create cool design with symbols (output omitted for brevity)
# ...

echo -n "Enter commonName: "
read commonName
echo -n "Enter organizationName (optional): "
read organizationName
echo -n "Enter organizationalUnitName (optional): "
read organizationalUnitName
echo -n "Enter emailAddress (optional): "
read emailAddress
echo -n "Enter serialNumber (optional): "
read serialNumber

# Generate 4096-bit RSA private key for the client
openssl genpkey -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out "$commonName.key"

# Create CSR using user-provided information and pre-defined extensions
cat <<EOF > "$commonName.cnf"
[ req ]
default_md = sha256
prompt = no
req_extensions = req_ext
distinguished_name = req_distinguished_name
[ req_distinguished_name ]
commonName = \$commonName
organizationName = ${organizationName:+O=$organizationName}
organizationalUnitName = ${organizationalUnitName:+OU=$organizationalUnitName}
emailAddress = ${emailAddress:+emailAddress=$emailAddress}
serialNumber = ${serialNumber:+serialNumber=$serialNumber}
[ req_ext ]
keyUsage=critical,digitalSignature,keyEncipherment,nonRepudiation,dataEncipherment,keyAgreement
extendedKeyUsage=critical,serverAuth,clientAuth,codeSigning,emailProtection,timeStamping,OCSPSigning,msCodeInd,msCodeCom,msCTLSign,msEFS,ipsecIKE,ipsecEndSystem,ipsecTunnel,ipsecUser
basicConstraints=critical,CA:false
tlsfeature=status_request
EOF

openssl req -new -nodes -key "$commonName.key" -config "$commonName.cnf" -out "$commonName.csr"

# Sign the CSR with the intermediate CA
openssl ca -in "$commonName.csr" -out "$commonName.crt" -cert intermediate.crt -keyfile intermediate.key -days 36525 -extensions v3_req -config <<-EOF
[ ca ]
default_ca = CA_default
[ CA_default ]
default_md = sha256
preserve = no
policy = policy_loose
[ policy_loose ]
countryName = optional
stateOrProvinceName = optional
localityName = optional
organizationName = optional
organizationalUnitName = optional
commonName = supplied
emailAddress = optional
EOF

# Create a full chain certificate
cat intermediate.crt root.crt > "$commonName.chain.pem"

# Export private key and certificate chain to P12 file
openssl pkcs12 -export -inkey "$commonName.key" -in "$commonName.crt" -certfile "$commonName.chain.pem" -out "$commonName.p12" -name "C-OSSL-B Client Certificate"

echo "Generated files:"
echo "- $commonName.key (private key)"
echo "- $commonName.csr (certificate signing request)"
echo "- $commonName.crt (certificate)"
echo "- $commonName.chain.pem (full chain certificate)"
echo "- $commonName.p12 (PKCS#12 bundle)"

# Clean up temporary configuration file
rm -f "$commonName.cnf"
