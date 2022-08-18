#!/bin/bash
set -e -o pipefail

CERT="${NEW_CERT_FILE:-/var/www/miq/vmdb/certs/server.cer}"
KEY="${NEW_KEY_FILE:-$CERT.key}"
if [ ! -f "$CERT" -a ! -f "$KEY" ]; then
  openssl req -x509 -newkey rsa -days 1095 -keyout $KEY -out $CERT -subj "/CN=server" -nodes -batch
  chmod 0660 $CERT $KEY
fi
