#!/bin/bash

BASEDIR="/var/www/miq/vmdb"
RETVAL=0
cd $BASEDIR

# Load default environment and variables
[[ -s "/etc/default/evm" ]] && source "/etc/default/evm"

/usr/bin/generate_miq_server_cert.sh

start() {
  bundle exec rake evm:start
  RETVAL=$?
  return $RETVAL
}

stop() {
  bundle exec rake evm:stop
  RETVAL=$?
  return $RETVAL
}

kill() {
  bundle exec rake evm:kill
  RETVAL=$?
  return $RETVAL
}

restart() {
  bundle exec rake evm:restart
  RETVAL=$?
  return $RETVAL
}

status() {
  bundle exec rake evm:status
  RETVAL=$?
  return $RETVAL
}

update_start() {
  bundle exec rake evm:update_start >> /var/www/miq/vmdb/log/evm.log 2>&1
  RETVAL=$?
  return $RETVAL
}

update_stop() {
  bundle exec rake evm:update_stop >> /var/www/miq/vmdb/log/evm.log 2>&1
  RETVAL=$?
  return $RETVAL
}

# See how we were called.
case "$1" in
  start)
  start
  ;;
  stop)
  stop
  ;;
  kill)
  kill
  ;;
  status)
  status
  ;;
  restart)
  restart
  ;;
  update_start)
  update_start
  ;;
  update_stop)
  update_stop
  ;;
  *)
  echo $"Usage: $prog {start|stop|restart|status}"
  exit 1
esac

exit $RETVAL
