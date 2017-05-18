#!/bin/bash
[[ -s /etc/default/evm ]] && source /etc/default/evm

# httpd needs to connect to backend workers on :3000 and :4000
setsebool -P httpd_can_network_connect on

# apply SELinux policies needed by the appliance
[[ -x /usr/bin/miqselinux.sh ]] && /usr/bin/miqselinux.sh

# backup the default ssl.conf
mv /etc/httpd/conf.d/ssl.conf{,.orig}

# https://bugzilla.redhat.com/show_bug.cgi?id=1020042
cat <<'EOF' > /etc/httpd/conf.d/ssl.conf
# This file intentionally left blank. ManageIQ maintains its own SSL
# configuration.  The presence of this file prevents the version
# supplied by mod_ssl from being installed when the mod_ssl package is
# upgraded.
EOF

/usr/sbin/semanage fcontext -a -t httpd_log_t "/var/www/miq/vmdb/log(/.*)?"
/usr/sbin/semanage fcontext -a -t cert_t "/var/www/miq/vmdb/certs(/.*)?"
/usr/sbin/semanage fcontext -a -t logrotate_exec_t ${APPLIANCE_SOURCE_DIRECTORY}/logrotate_free_space_check.sh
/usr/sbin/semanage fcontext -a -t etc_t "/var/www/miq/vmdb/config/cockpit"

cat <<'EOF' > /tmp/cockpit_ws_port.te
module cockpit_ws_port 1.0;

require {
    attribute port_type;
	type cockpit_ws_t;
	class tcp_socket { name_bind };
}

type cockpit_ws_port_t, port_type;
allow cockpit_ws_t cockpit_ws_port_t:tcp_socket name_bind;
EOF
checkmodule -M -m -o /tmp/cockpit_ws_port.mod /tmp/cockpit_ws_port.te
semodule_package -o /tmp/cockpit_ws_port.pp -m /tmp/cockpit_ws_port.mod
semodule -i /tmp/cockpit_ws_port.pp

semanage port -a -t cockpit_ws_port_t -p tcp 9002

[ -x /sbin/restorecon ] && /sbin/restorecon -R -v /var/www/miq/vmdb/log
[ -x /sbin/restorecon ] && /sbin/restorecon -R -v /etc/sysconfig
[ -x /sbin/restorecon ] && /sbin/restorecon -R -v /var/www/miq/vmdb/certs
[ -x /sbin/restorecon ] && /sbin/restorecon -R -v ${APPLIANCE_SOURCE_DIRECTORY}/logrotate_free_space_check.sh
[ -x /sbin/restorecon ] && /sbin/restorecon -R -v "/var/www/miq/vmdb/config/cockpit"

# relabel the pg_log directory in postgresql datadir, but defer restorecon
# until after the database is initialized during firstboot configuration
/usr/sbin/semanage fcontext -a -t var_log_t "${APPLIANCE_PG_DATA}/pg_log(/.*)?"

# setup label for postgres client certs, but relabel after dir is created
/usr/sbin/semanage fcontext -a -t cert_t "/root/.postgresql(/.*)?"
# will remove this once app is no longer running as root
/usr/sbin/semanage fcontext -a -t user_home_dir_t "/root(/)?"
/sbin/restorecon /root

# ActionCable configuration
cp /var/www/miq/vmdb/config/cable.yml.sample /var/www/miq/vmdb/config/cable.yml
