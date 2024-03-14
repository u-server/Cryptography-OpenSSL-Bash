#!/bin/bash

clear

# Create cool design with symbols (optional, uncomment if desired)
# echo "   _ _  _ _  _ _   _ _ "
# echo "   | | | ( )(_| | | | |  | | |"
# echo "   | |_| |/ / _ \ |_| |__ | | |"
# echo "   | __|  | (_) | __| '_ \| | |"
# echo "   |_|   |_|\___|_| |_.__/|_| |"

echo -n "Enter commonName (server hostname, e.g., domain.example.com): "
read commonName

echo -n "Enter organizationName (optional): "
read organizationName
echo -n "Enter organizationalUnitName (optional): "
read organizationalUnitName

# Function to generate Subject Alternative Name (SAN) string
get_san() {
  local IFS=,
  san_list=""
  while read -r domain ip; do
    if [[ ! -z "$domain" ]]; then
      san_list+="DNS:$domain,"
    fi
    if [[ ! -z "$ip" ]]; then
      san_list+="IP:$ip,"
    fi
  done < "$1"
  echo "${san_list::-1}"  # Remove trailing comma
}

# Read domain/IP list file
echo "Enter path to file containing domain/IP entries (one line per entry, domain,ip): "
read domain_ip_file

if [[ ! -f "$domain_ip_file" ]]; then
  echo "Error: File '$domain_ip_file' not found!"
  exit 1
fi

# Generate SAN string from domain/IP file
san_string=$(get_san "$domain_ip_file")

# Generate 4096-bit RSA private key for the server
openssl genpkey -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out server.key

# Create CSR using user-provided information, pre-defined extensions, and SAN
cat <<EOF > server.cnf
[ req ]
default_md = sha256
prompt = no
req_extensions = req_ext
distinguished_name = req_distinguished_name
[ req_distinguished_name ]
commonName = \$commonName
organizationName = ${organizationName:+O=$organizationName}
organizationalUnitName = ${organizationalUnitName:+OU=$organizationalUnitName}
[ req_ext ]
subjectAltName = $san_string
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
basicConstraints=critical,CA:false
tlsfeature=status_request
EOF

openssl req -new -nodes -key server.key -config server.cnf -out server.csr

# Sign the CSR with the Root CA (replace with your actual Root CA paths)
openssl x509 -req -in server.csr -CA root.crt -CAkey root.key -CAcreateserial \
  -days 36525 -sha256 -extfile server.cnf -extensions req_ext -out server.crt

# Create a full chain certificate (server + root)
cat server.crt root.crt > server.chain.pem

# Export private key and certificate chain to P12 file (optional)
openssl pkcs12 -export -inkey server.key -in server.crt -certfile server.chain.pem -out server.p12 -name "C-OSSL-B Web Server Certificate"

echo "Generated files:"
echo "- server.key (private key)"
echo "- server.csr (certificate signing request)"
echo "- server.crt (certificate)"
echo "- server.chain.pem (full chain certificate)"
# Uncomment the line below if you enabled P12 export
# echo "- server.p12 (PKCS#12 bundle)"

# Clean up temporary configuration file
rm -f server.cnf

echo "To view the SAN names in the server certificate, use the following command:"
echo "openssl x509 -in server.crt -noout -text | grep Subject:Alt"

