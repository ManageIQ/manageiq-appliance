[[ -s "/etc/default/evm" ]] && source "/etc/default/evm"

# Aliases:
alias ap='/usr/bin/appliance_console'
alias vmdb='cd /var/www/miq/vmdb'
alias appliance='[[ -n ${APPLIANCE_SOURCE_DIRECTORY} ]] && cd ${APPLIANCE_SOURCE_DIRECTORY}'

# Tail MIQ Logs:
function tailmiq()
{
  tail -f /var/www/miq/vmdb/log/${1:-evm}.log
}
alias tailpglog='tail -f $APPLIANCE_PG_DATA/pg_log/postgresql.log'

# Rails Console:
alias railsc="cd /var/www/miq/vmdb;echo '\$evm = MiqAeMethodService::MiqAeService.new(MiqAeEngine::MiqAeWorkspaceRuntime.new)'; rails c"

# Appliance Status:
alias apstatus='echo "EVM Status:";service evmserverd status;echo " ";echo "HTTP Status:";service httpd status'
