#!/bin/bash
[[ -s /etc/default/evm ]] && source /etc/default/evm

pushd /var/www/miq/vmdb
  # rails compile tasks loads environment which needs above shared objects
  # There is no database.yml. Bogus database parameters appeases rails.
  RAILS_ENV=production rake evm:compile_assets
popd

# httpd needs to connect to backend workers on :3000 and :4000
setsebool -P httpd_can_network_connect on

# backup the default ssl.conf
mv /etc/httpd/conf.d/ssl.conf{,.orig}

# https://bugzilla.redhat.com/show_bug.cgi?id=1020042
cat <<'EOF' > /etc/httpd/conf.d/ssl.conf
# This file intentionally left blank.  CFME maintains its own SSL
# configuration.  The presence of this file prevents the version
# supplied by mod_ssl from being installed when the mod_ssl package is
# upgraded.
EOF

# Alter cloud-init config to allow root ssh access to the appliance
[[ -s /etc/cloud/cloud.cfg ]] && sed -i "s/^ssh_pwauth:.*$/ssh_pwauth: True/g" /etc/cloud/cloud.cfg
[[ -s /etc/cloud/cloud.cfg ]] && sed -i "s/^disable_root:.*$/disable_root: false/g" /etc/cloud/cloud.cfg

# Alter cloud-init logging config to prevent logging to the console
[[ -s /etc/cloud/cloud.cfg.d/05_logging.cfg ]] && sed -i "s/handlers=consoleHandler,cloudLogHandler/handlers=cloudLogHandler/g" /etc/cloud/cloud.cfg.d/05_logging.cfg
[[ -s /etc/cloud/cloud.cfg.d/05_logging.cfg ]] && sed -i "/^ - \[ \*log_base, \*log_syslog \]/d" /etc/cloud/cloud.cfg.d/05_logging.cfg
[[ -s /etc/cloud/cloud.cfg.d/05_logging.cfg ]] && sed -i "s/^output:.*$/output: {all: '| tee -a \/var\/log\/cloud-init-output\.log \&> \/dev\/null'}/g" /etc/cloud/cloud.cfg.d/05_logging.cfg
[[ -s /usr/lib/systemd/system/cloud-config.service ]] && sed -i "s/^StandardOutput=.*/StandardOutput=journal/g" /usr/lib/systemd/system/cloud-config.service
[[ -s /usr/lib/systemd/system/cloud-final.service ]] && sed -i "s/^StandardOutput=.*/StandardOutput=journal/g" /usr/lib/systemd/system/cloud-final.service
[[ -s /usr/lib/systemd/system/cloud-init-local.service ]] && sed -i "s/^StandardOutput=.*/StandardOutput=journal/g" /usr/lib/systemd/system/cloud-init-local.service
[[ -s /usr/lib/systemd/system/cloud-init.service ]] && sed -i "s/^StandardOutput=.*/StandardOutput=journal/g" /usr/lib/systemd/system/cloud-init.service

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
