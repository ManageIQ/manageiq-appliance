#!/bin/bash
# description: dump miq_server table to YAML file

export PGPASSWORD="${PGPASSWORD:-smartvm}"
/var/www/miq/vmdb/tools/pg_inspector.rb servers
