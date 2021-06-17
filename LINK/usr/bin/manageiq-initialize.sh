#!/bin/sh
[[ -d /var/lib/pgsql/data/base ]] && exit 0
[[ -s /etc/default/evm ]] && source /etc/default/evm
echo "Initializing Appliance, please wait ..." > /dev/tty1
appliance_console_cli --region 0 --internal --password smartvm --key
appliance_console_cli --message-server-config --message-server-use-ipaddr --message-keystore-username="admin" --message-keystore-password="smartvm"
