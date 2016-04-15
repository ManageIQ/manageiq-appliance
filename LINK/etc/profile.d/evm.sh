[[ -s "/etc/default/evm" ]] && source "/etc/default/evm"

# Aliases:
alias ap='/usr/bin/appliance_console'
alias vmdb='cd /var/www/miq/vmdb'
alias appliance='[[ -n ${APPLIANCE_SOURCE_DIRECTORY} ]] && cd ${APPLIANCE_SOURCE_DIRECTORY}'
