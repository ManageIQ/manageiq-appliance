#!/bin/bash
set -e -o pipefail

KEYPATH="/var/www/miq/vmdb/certs"

[[ ! -f "$KEYPATH/v2_key" ]] && appliance_console_cli --key

CERT="$KEYPATH/server.cer"
KEY="$CERT.key"
if [ ! -f "$CERT" -a ! -f "$KEY" ]; then
  (umask 077 ; openssl req -x509 -newkey rsa -days 1095 -keyout $KEY -out $CERT -subj "/CN=server" -nodes -batch)
fi
