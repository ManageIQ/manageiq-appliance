[[ -s "/etc/default/evm" ]] && source "/etc/default/evm"

# Aliases:
alias ap='/usr/bin/appliance_console'
alias vmdb='cd /var/www/miq/vmdb'
alias appliance='[[ -n ${APPLIANCE_SOURCE_DIRECTORY} ]] && cd ${APPLIANCE_SOURCE_DIRECTORY}'

# Tail Log Aliases:
alias tailauto='tail -f /var/www/miq/vmdb/log/automation.log'
alias tailevm='tail -f /var/www/miq/vmdb/log/evm.log'
alias tailaws='tail -f /var/www/miq/vmdb/log/aws.log'
alias tailfog='tail -f /var/www/miq/vmdb/log/fog.log'
alias tailrhevm='tail -f /var/www/miq/vmdb/log/rhevm.log'
alias tailprod='tail -f /var/www/miq/vmdb/log/production.log'
alias tailpolicy='tail -f /var/www/miq/vmdb/log/policy.log'
alias tailpglog='tail -f /var/opt/rh/rh-postgresql95/lib/pgsql/data/pg_log/postgresql.log'

# Rails Console:
alias railsc="cd /var/www/miq/vmdb;echo '\$evm = MiqAeMethodService::MiqAeService.new(MiqAeEngine::MiqAeWorkspaceRuntime.new)'; rails c"

# Appliance status:
alias apstatus='echo "EVM Status:";service evmserverd status;echo " ";echo "HTTP Status:";service httpd status'
