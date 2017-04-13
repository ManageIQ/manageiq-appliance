#!/bin/bash
# chkconfig: 2345 01 15
# description: Initializes the evm environment
#

[[ -s /etc/default/evm ]] && source /etc/default/evm

# Some variables to shorten things
VMDBDIR=/var/www/miq/vmdb
EVMLOG=$VMDBDIR/log/evm.log
PID_DIR=$VMDBDIR/tmp/pids


# Log to evm.log that appliance booted
echo `date -u` 'EVMINIT   EVM Appliance Booted' >> $EVMLOG
rm -rfv $PID_DIR/evm.pid >> $EVMLOG


# Rescan for LVM Physical Volumes since RHEV DirectLUN PV's aren't always found.
# Skip pvscan when running on container platforms

if [[ -n ${CONTAINER} ]]; then
  echo "Skipping pvscan on container platforms.."
else
  pvscan
fi
