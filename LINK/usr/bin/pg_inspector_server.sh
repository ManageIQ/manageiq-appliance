#!/bin/bash
# description: dump miq_server table to YAML file
exec 2>&1
export PGPASSWORD="${PGPASSWORD:-smartvm}"
[[ -s /etc/default/evm ]] && source /etc/default/evm
export PATH=$PATH:/usr/local/bin
/var/www/miq/vmdb/tools/pg_inspector.rb servers
