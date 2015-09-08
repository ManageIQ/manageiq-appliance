[[ -s "/etc/default/evm" ]] && source "/etc/default/evm"

# Aliases:
alias vmdb='cd /var/www/miq/vmdb'
alias appliance='[[ -n ${APPLIANCE_SOURCE_DIRECTORY} ]] && cd ${APPLIANCE_SOURCE_DIRECTORY}'
