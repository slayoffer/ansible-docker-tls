#!/bin/bash

# Certificates location
CERT_DIR=/home/slayo/certs
CLIENT_CERTIFICATE=$CERT_DIR/client/cert.pem
CLIENT_PRIVATEKEY=$CERT_DIR/client/ca-key.pem
ROOTCA_CERTIFICATE=$CERT_DIR/ca.pem

# Remote Host
HOST=10.0.0.9

dockerd \
  --tlscert $CLIENT_CERTIFICATE \
  --tlskey $CLIENT_PRIVATEKEY \
  --tlsverify \
  --tlscacert $ROOTCA_CERTIFICATE \
  --host=tcp://$HOST:2376 \