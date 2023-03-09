#!/bin/bash

set -eu

#set -x ; debugging

cd ~
echo "you are now in $PWD"

if [ ! -d ".docker/" ] 
then
    echo "Directory ./docker/ does not exist"
    echo "Creating the directory"
    mkdir -pv ~/.docker
fi

cd .docker/

echo "type in your certificate password (characters are not echoed)"
read -p '>' -s PASSWORD

echo "Type in the FQDN server name you'll use to connect to the Docker server"
read -p '>' SERVER

# 256bit AES (Advanced Encryption Standard) is the encryption cipher which is used for generating certificate authority (CA) with 4096-bit security.
openssl genrsa -aes256 -passout pass:"$PASSWORD" -out ca-key.pem 4096

# Sign the the previously created CA key with your password and address for a period of ... years.
# i.e. generating a self-signed certificate for CA
# X.509 is a standard that defines the format of public key certificates, with fixed size 256-bit (32-byte) hash
openssl req -new -x509 -days 3650 -key ca-key.pem -passin pass:"$PASSWORD" -sha256 -out ca.pem -subj "/C=TR/ST=./L=./O=./CN=$SERVER"

# Generating a server key with 4096-bit security
openssl genrsa -out server-key.pem 4096

# Generating a certificate signing request (CSR) for the the server key with the name of your host.
openssl req -subj "/CN=$SERVER" -sha256 -new -key server-key.pem -out server.csr

# CHANGE IPs here! THESE ARE IPS WHICH DOCKER CLIENTS CAN ACCESS THROUGH
# Since TLS connections can be made through IP address as well as DNS name
# the IP addresses need to be specified when creating the certificate
echo subjectAltName = DNS:"$SERVER",DNS:"server-docker-2",DNS:"server-docker-2.rubius.rubius.com",IP:192.168.10.175,IP:127.0.0.1 >> extfile.cnf

# Set the Docker daemon key’s extended usage attributes to be used only for server authentication:
echo extendedKeyUsage = serverAuth >> extfile.cnf

# Sign the key with your password for a period of ... years
# i.e. generating a self-signed certificate for the key
openssl x509 -req -days 3650 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -passin "pass:$PASSWORD" \
  -CAcreateserial -out server-cert.pem -extfile extfile.cnf

# For client authentication, create a client key and certificate signing request
# Generate a client key with 4096-bit security
openssl genrsa -out key.pem 4096

# Process the key as a client key.
openssl req -subj '/CN=client' -new -key key.pem -out client.csr

# To make the key suitable for client authentication, create an extensions config file:
echo extendedKeyUsage = clientAuth > extfile-client.cnf

# Sign the (public) key with your password for a period of ... years
openssl x509 -req -days 3650 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -passin "pass:$PASSWORD" \
  -CAcreateserial -out cert.pem -extfile extfile-client.cnf

echo "Removing unnecessary files i.e. client.csr extfile.cnf server.csr"
rm -v client.csr server.csr extfile.cnf extfile-client.cnf

echo "Changing the permissions to readonly by root for the server files."
# To make them only readable by you: 
chmod -v 0400 ca-key.pem key.pem server-key.pem

echo "Changing the permissions of the client files to read-only by everyone"
# Certificates can be world-readable, but you might want to remove write access to prevent accidental damage
# these are all x509 certificates aka public key certificates
# X.509 certificates are used in many Internet protocols, including TLS/SSL, which is the basis for HTTPS.
chmod -v 0444 ca.pem server-cert.pem cert.pem
