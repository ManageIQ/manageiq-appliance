[[ -s "/etc/default/evm" ]] && source "/etc/default/evm"

# Aliases:
alias vmdb='cd /var/www/miq/vmdb'
alias appliance='[[ -n ${APPLIANCE_REPO_DIRECTORY} ]] && cd ${APPLIANCE_REPO_DIRECTORY}'
