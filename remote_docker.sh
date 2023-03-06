#!/bin/bash

# Certificates location
CERT_DIR=/home/administrator/certs
CLIENT_CERTIFICATE=$CERT_DIR/client/client-certificate.pem
CLIENT_PRIVATEKEY=$CERT_DIR/client/client-privatekey.pem
ROOTCA_CERTIFICATE=$CERT_DIR/rootca-certificate.pem

# Remote Host
HOST=docker-host.com

dockerd \
  --tlscert $CLIENT_CERTIFICATE \
  --tlskey $CLIENT_PRIVATEKEY \
  --tlsverify \
  --tlscacert $ROOTCA_CERTIFICATE \
  --host=tcp://$HOST:2376 \


