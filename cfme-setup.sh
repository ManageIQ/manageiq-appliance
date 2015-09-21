#!/bin/bash
[[ -s /etc/default/evm ]] && source /etc/default/evm

pushd /var/www/miq/vmdb
  RAILS_ENV=production rake evm:compile_assets
popd

# Self Service UI
pushd /var/www/miq/vmdb/spa_ui/self_service
  npm install gulp bower -g
  npm install
  bower install
  gulp build
popd

# httpd needs to connect to backend workers on :3000 and :4000
setsebool -P httpd_can_network_connect on

# app needs an selinux policy to access sssd via dbus
if [ -z "`/sbin/semodule -l | grep '^init_dbus_sssd '`" ]
then
  SMOD=/tmp/miq_init_dbus_sssd
  cat - >$SMOD.te <<!END!
module init_dbus_sssd 1.0;

require {
  type sssd_t;
  type initrc_t;
  class dbus send_msg;
}

allow sssd_t initrc_t:dbus send_msg;
!END!
  /usr/bin/checkmodule -M -m -o $SMOD.mod $SMOD.te
  /usr/bin/semodule_package -m $SMOD.mod -o $SMOD.pp
  /sbin/semodule -i $SMOD.pp
  rm -f $SMOD.te $SMOD.mod $SMOD.pp
fi

# backup the default ssl.conf
mv /etc/httpd/conf.d/ssl.conf{,.orig}

# https://bugzilla.redhat.com/show_bug.cgi?id=1020042
cat <<'EOF' > /etc/httpd/conf.d/ssl.conf
# This file intentionally left blank.  CFME maintains its own SSL
# configuration.  The presence of this file prevents the version
# supplied by mod_ssl from being installed when the mod_ssl package is
# upgraded.
EOF

/usr/sbin/semanage fcontext -a -t httpd_log_t "/var/www/miq/vmdb/log(/.*)?"
/usr/sbin/semanage fcontext -a -t cert_t "/var/www/miq/vmdb/certs(/.*)?"
/usr/sbin/semanage fcontext -a -t logrotate_exec_t ${APPLIANCE_SOURCE_DIRECTORY}/logrotate_free_space_check.sh

[ -x /sbin/restorecon ] && /sbin/restorecon -R -v /var/www/miq/vmdb/log
[ -x /sbin/restorecon ] && /sbin/restorecon -R -v /etc/sysconfig
[ -x /sbin/restorecon ] && /sbin/restorecon -R -v /var/www/miq/vmdb/certs
[ -x /sbin/restorecon ] && /sbin/restorecon -R -v ${APPLIANCE_SOURCE_DIRECTORY}/logrotate_free_space_check.sh

# relabel the pg_log directory in postgresql datadir, but defer restorecon
# until after the database is initialized during firstboot configuration
/usr/sbin/semanage fcontext -a -t var_log_t "${APPLIANCE_PG_DATA}/pg_log(/.*)?"

# setup label for postgres client certs, but relabel after dir is created
/usr/sbin/semanage fcontext -a -t cert_t "/root/.postgresql(/.*)?"
# will remove this once app is no longer running as root
/usr/sbin/semanage fcontext -a -t user_home_dir_t "/root(/)?"
/sbin/restorecon /root
