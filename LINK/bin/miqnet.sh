#!/bin/sh

export ERR_FILE="/etc/init.d/miqnet.err"
export TMP_IO="/tmp/tmp_io"
export LOG_DIR="/var/www/miq/vmdb/log"
export LOG_FILE="$LOG_DIR/appliance_console.log"
export BACKUP_DIR="/var/www/miq/vmdb/config"
export RAILS_ROOT="/var/www/miq/vmdb"
export PIDFILE="$RAILS_ROOT/tmp/pids/evm.pid"
export EVMLOG="$LOG_DIR/evm.log"
export DISTRO="redhat"

# How many seconds should we wait for the various daemons to stop?
export VMDB_STOP_TIMER=15

USAGETEXT="USAGE:\n \
 miqnet.sh -GET [HOST | TIMESERVER | MAC | IP | MASK | GW | DNS1 | DNS2 | SEARCHORDER | TIMEZONE]\n \
 miqnet.sh -DHCP\n \
 miqnet.sh -STATIC ipaddress netmask gateway primarydns [secondarydns]\n \
 miqnet.sh -SEARCHORDER domain1.com[;domain2.com]...\n \
 miqnet.sh -HOST hostname\n \
 miqnet.sh -TIMESERVER timeserver\n \
 miqnet.sh -RESTART\n \
 miqnet.sh -RESTARTOS\n \
 miqnet.sh -RESTARTOSRMLOGS\n \
 miqnet.sh -SHUTDOWN\n \
 miqnet.sh -TIME date time\n \
 miqnet.sh -TIMEZONE area city\n"

log() {
  echo "$(date) $(date +%z): $@" >> $LOG_FILE
}

get_hostname () {
  hostname
}

get_timeserver () {
  awk '/^server/ { print $2}' /etc/chrony.conf
}

get_mac () {
  ###
  ## TODO: Remove hard coded eth0
  ###
  ip addr show eth0 | awk '/ether/ { print $2 }'
}

get_ip () {
  hostname -I | cut -d' ' -f1
}

get_netmask () {
  ifconfig eth0 | awk '/netmask/ { print $4 }' | cut -d: -f2
}

get_gateway () {
  ip route | awk '/^default/ { print $3 }'
}

get_dns1 () {
  # Redirect any stderr 'cat: /etc/resolv.conf: No such file or directory'  messages to /dev/null
  cat /etc/resolv.conf 2> /dev/null | awk '/^nameserver/ { print $2; exit }'
}

get_dns2 () {
  # Redirect any stderr 'cat: /etc/resolv.conf: No such file or directory'  messages to /dev/null
  cat /etc/resolv.conf 2> /dev/null | awk '
    BEGIN { skip = 1 }
    /^nameserver/ {
      if (skip == 1) { skip = 0; next }
      print $2
      exit
    }
  '
}

get_search_order () {
  # Redirect any stderr 'cat: /etc/resolv.conf: No such file or directory'  messages to /dev/null
  cat /etc/resolv.conf 2> /dev/null | awk '/^search/ { print substr($0,8,length($0)-7) }'
}

get_timezone () {
  timedatectl status | awk '/Timezone/ {print $2}'
}

get_info () {
  case $1 in
    HOST | host) get_hostname;;
    MAC | mac) get_mac;;
    IP | ip) get_ip;;
    MASK | mask) get_netmask;;
    GW | gw) get_gateway;;
    DNS1 | dns1) get_dns1;;
    DNS2 | dns2) get_dns2;;
    SEARCHORDER | searchorder) get_search_order;;
    TIMESERVER | timeserver) get_timeserver;;
    TIMEZONE | timezone) get_timezone;;
    *)
      if [ ! -z $1 ]; then
        echo -e $USAGETEXT >&2
        exit 1
      fi
      echo `get_hostname` `get_mac` `get_ip` `get_netmask` `get_gateway` `get_dns1` `get_dns2`
      ;;
  esac
}

set_time() {
  log "set_time: args: $@"

  if [ $# -ne 2 ]; then
    echo -e $USAGETEXT >&2
    exit 1
  fi

  timedatectl set-time "${1} ${2}" --adjust-system-clock
}

set_timezone() {
  log "set_timezone: args: $@"

  if [ $# -ne 2 ]; then
    echo -e $USAGETEXT >&2
    exit 1
  fi

  timedatectl set-timezone "${1}/${2}"
}

set_hostname() {
  if [ -z ${1} ]; then
    echo -e ${USAGETEXT} >&2
    exit 1
  fi

  log "set_hostname: old hostname: $(hostname)"

  hostnamectl set-hostname ${1}

  # Update or add the hostname to the associated ip address
  grep -E "^${IP_ADDR}" /etc/hosts > /dev/null
  if [ $? -eq 0 ]; then
    sed "s/\(^${IP_ADDR}\>\s*\)\(.*\<.*$\)/\1${1}/" /etc/hosts > /etc/hosts.new
    mv /etc/hosts.new /etc/hosts
  else
    echo -e "${IP_ADDR}\t\t${1}" >> /etc/hosts
  fi

  systemctl restart network > /dev/null 2>> $ERR_FILE

  log "set_hostname: new hostname: $(hostname)"
}

restart_os() {
  LOG_LINE='[----] I, ['`date -u`']  APPLIANCE RESTART initiated by MIQ Console.' && echo $LOG_LINE >> $EVMLOG && echo $LOG_LINE >> $LOG_FILE
  stop_vmdb
  shutdown -r now
}

restart_os_rm_logs() {
  LOG_LINE='[----] I, ['`date -u`']  APPLIANCE RESTART WITH CLEAN LOGS initiated by MIQ Console.' && echo $LOG_LINE >> $EVMLOG && echo $LOG_LINE >> $LOG_FILE
  stop_vmdb
  stop_miqtop
  stop_miqvmstat
  stop_httpd
  rm -rf /var/www/miq/vmdb/log/*.log*
  rm -rf /var/www/miq/vmdb/log/apache/*.log*
  LOG_LINE='[----] I, ['`date -u`']  LOGS CLEANED AND APPLIANCE REBOOTED by MIQ Console.' && echo $LOG_LINE >> $EVMLOG && echo $LOG_LINE >> $LOG_FILE
  shutdown -r now
}

shutdown_os() {
  LOG_LINE='[----] I, ['`date -u`']  APPLIANCE SHUTDOWN initiated by MIQ Console.' && echo $LOG_LINE >> $EVMLOG && echo $LOG_LINE >> $LOG_FILE
  stop_vmdb
  shutdown -h 0
}

set_timeserver() {
  if [ -z $1 ]; then
      echo -e $USAGETEXT >&2
      exit 1
  fi

  if [ $(grep -c $1 /etc/chrony.conf) -ne 0 ]; then
      echo "miqnet.sh: server $1 already registered in /etc/chrony.conf"
      exit 1
  else
      echo -e "\n# Added by miqnet.sh\nserver $1" >> /etc/chrony.conf
  fi
}

set_static () {
  log "set_static: args: $@"
  if [ $# -lt 4 ]; then
    echo -e $USAGETEXT >&2
    exit 1
  fi

  # Verify IP address formats
  for i
  do
    echo $i | grep -q '^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$' > /dev/null
    if [ $? -ne 0 ]; then
      echo "Invalid IP address format." >&2
      exit 1
    fi
  done

  # Create the /etc/resolv.conf empty if it doesn't exist
  if [ ! -f '/etc/resolv.conf' ]; then
    :> /etc/resolv.conf
    log "set_static: Created empty /etc/resolv.conf"
  fi

  set_${DISTRO}_static "$@"

  log "set_static: resolve old: $(cat /etc/resolv.conf)"
  # Modify DNS entries in /etc/resolv.conf
  grep -v -E "^(nameserver|search)" /etc/resolv.conf > /etc/resolv.conf.new
  echo nameserver $4 >> /etc/resolv.conf.new
  if [ ! -z $5 ]; then
    echo nameserver $5 >> /etc/resolv.conf.new
  fi
  mv /etc/resolv.conf.new /etc/resolv.conf
  log "set_static: resolve new: $(cat /etc/resolv.conf)"
}

set_redhat_static () {
  log "set_redhat_static: args: $@"
  ipfirst3=`echo $1 | sed 's/\.[0-9]\+$//'`
  ipfirst2=`echo $ipfirst3 | sed 's/\.[0-9]\+$//'`

  # 1) update the BOOTPROTO, BROADCAST, IPADDR, NETMASK, NETWORK in ifcfg-eth0
  cfg="/etc/sysconfig/network-scripts/ifcfg-eth0"
  resolv="/etc/resolv.conf"
  network="/etc/sysconfig/network"

  # Backup ifcfg file
  cp $cfg ${cfg}.bak

  # Get the old ip address
  old_ip=$(hostname -I | cut -d' ' -f1)

  # Bring down eth0
  ifdown eth0 > /dev/null 2>&1

  log "set_redhat_static: cfg old: $(cat ${cfg})"
  # /etc/sysconfig/network-scripts/ifcfg-eth0: Replace some entries, but remove any NETWORK or GATEWAY values
  grep -v -E "^(BOOTPROTO|BROADCAST|IPADDR|NETMASK|NETWORK|GATEWAY)" $cfg > ${cfg}.tmp

  # append the temp file with the data we are replacing
  echo "BOOTPROTO=static
BROADCAST=${ipfirst3}.255
IPADDR=${1}
NETMASK=${2}
GATEWAY=${3}
NM_CONTROLLED=no
DNS1=${4}" >> ${cfg}.tmp
  mv ${cfg}.tmp $cfg
  log "set_redhat_static: cfg new: $(cat ${cfg})"

  # Truncate the temporary io file
  :> $TMP_IO

  /sbin/restorecon -R /etc/sysconfig

  # 2) reload config and bring up the interface to see if it worked
  systemctl restart network > /dev/null 2>> $ERR_FILE
  ifup eth0 >> $TMP_IO 2 >> $ERR_FILE
  if [ $? -ne 0 ]; then
    cat $TMP_IO >> $ERR_FILE
    log "set_redhat_static: ifup eth0 failed due to error: $(cat $ERR_FILE)...reloading from backup"
    # Restore from backup and exit
    mv ${cfg}.bak $cfg
    systemctl restart network > /dev/null 2>&1
    ifup eth0 > /dev/null 2>&1
    echo "Unable to set static network configuration." >&2
    rm -f /tmp/miq_errors
    exit 1
  fi

  rm -f ${cfg}.bak

  log "set_redhat_static: network cfg old: $(cat ${network})"

  #3 /etc/sysconfig/network: enable networking, populate gateway
  cat $network | grep -v -E "^(NETWORKING|GATEWAY)" > ${network}.tmp
  echo "NETWORKING=yes
GATEWAY=${3}" >> ${network}.tmp
  mv ${network}.tmp $network
  log "set_redhat_static: network cfg new: $(cat ${network})"
  log "set_redhat_static: route old: $(route)"

  # 4) Remove an old default gateway and add the new one
  # Append to the ERR_FILE anything written to stderr when deleting or adding routes
  old=`route -n | awk '/^0\.0\.0\.0/ { print $2 }'`
  if [ ! -z $old ]; then
    route delete default gw $old > /dev/null 2>> $ERR_FILE
  fi
  route add default gw $3 > /dev/null 2>> $ERR_FILE
  log "set_redhat_static: route new: $(route)"

  # 5) remove all other copies of /etc/resolv.conf
  for conf in "/etc/sysconfig/networking/profiles/default/resolv.conf ${resolv}.predhclient"
  do
    rm -f $conf
  done

  # Backup hosts
  cp /etc/hosts /etc/hosts.bak

  log "set_redhat_static: hosts old: $(cat /etc/hosts)"
  # Update the ipaddress associated with our hostname
  hn=$(get_hostname)
  grep -E "^$old_ip" /etc/hosts > /dev/null
  if [ $? -eq 0 ]; then
    # Change the ip associated with the hostname to the new ip
    sed "s/\(^$old_ip\)\(\>\s*.*\<.*$\)/$1\2/" /etc/hosts > /etc/hosts.new
    mv /etc/hosts.new /etc/hosts
  else
    # Add a line with the new ip and the existing hostname
    echo -e "$1\t\t$hn" >> /etc/hosts
  fi
  rm /etc/hosts.bak
  log "set_redhat_static: hosts new: $(cat /etc/hosts)"
}

set_search_order() {
  # Convert semicolon delimiter to space: manageiq.com;galaxy.local to manageiq.com galaxy.local
  new_order=`echo $@ | sed "s/;\+/ /g"`
  log "set_search_order: args: $@, new search order: $new_order"
  if [ $# -lt 1 ]; then
    echo -e $USAGETEXT >&2
    exit 1
  fi

  # Create the /etc/resolv.conf empty if it doesn't exist
  if [ ! -f '/etc/resolv.conf' ]; then
    :> /etc/resolv.conf
    log "set_search_order: Created empty /etc/resolv.conf"
  fi

  log "set_search_order: resolve old: $(cat /etc/resolv.conf)"
  # Modify domain search entries in /etc/resolv.conf
  grep -v -E "^search" /etc/resolv.conf > /etc/resolv.conf.new
  echo "search $new_order" >> /etc/resolv.conf.new
  mv /etc/resolv.conf.new /etc/resolv.conf
  log "set_search_order: resolve new: $(cat /etc/resolv.conf)"
}

set_dhcp() {
  # Create the /etc/resolv.conf empty if it doesn't exist
  if [ ! -f '/etc/resolv.conf' ]; then
    :> /etc/resolv.conf
    log "set_dhcp: Created empty /etc/resolv.conf"
  fi

  # Remove the nameserver and search lines in /etc/resolv.conf since dhcp will populate them
  log "set_dhcp: resolve old: $(cat /etc/resolv.conf)"
  grep -v -E "^(nameserver|search)" /etc/resolv.conf > /etc/resolv.conf.new
  mv /etc/resolv.conf.new /etc/resolv.conf

  set_${DISTRO}_dhcp "$@"
  log "set_dhcp: resolve new: $(cat /etc/resolv.conf)"
}

set_redhat_dhcp() {
  # TODO: Redirect all output to /dev/null so it's not displayed on the console
  # 1) update the BOOTPROTO, BROADCAST, IPADDR, NETMASK, NETWORK in ifcfg-eth0 (removing all of these but the BOOTPROTO=dhcp)
  cfg="/etc/sysconfig/network-scripts/ifcfg-eth0"
  resolv="/etc/resolv.conf"
  network="/etc/sysconfig/network"

  # Backup ifcfg file
  cp $cfg ${cfg}.bak

  old_ip=$(get_ip)
  # Bring down eth0
  ifdown eth0 > /dev/null 2>&1

  log "set_redhat_dhcp: cfg old: $(cat ${cfg})"
  # Capture the data that we will be replacing into a temp file
  grep -v -E "^(BOOTPROTO|BROADCAST|IPADDR|NETMASK|NETWORK)" $cfg > ${cfg}.tmp

  # append the temp file with the data we are replacing
  echo "BOOTPROTO=dhcp" >> ${cfg}.tmp
  mv ${cfg}.tmp $cfg
  log "set_redhat_dhcp: cfg new: $(cat ${cfg})"
  log "set_redhat_dhcp: network old: $(cat ${network})"
  # 2) Remove the GATEWAY lines in /etc/sysconfig/network
  cat $network | grep -v -E "^(NETWORKING|GATEWAY)" > ${network}.tmp
  echo "NETWORKING=yes" >> ${network}.tmp
  mv ${network}.tmp $network
  log "set_redhat_dhcp: network new: $(cat ${network})"

  log "set_redhat_dhcp: route old: $(route)"
  # 3) Remove the default GW route
  old=`route -n | awk '/^0\.0\.0\.0/ { print $2 }'`
  if [ ! -z $old ]; then
    route delete default gw $old > /dev/null 2>> $ERR_FILE
  fi
  log "set_redhat_dhcp: route new: $(route)"

  # Truncate the temporary io file
  :> $TMP_IO

  /sbin/restorecon -R /etc/sysconfig

  # 4) Start the interface to see if it worked
  ifup eth0 >> $TMP_IO 2>> $ERR_FILE
  if [ $? -ne 0 ]; then
    cat $TMP_IO >> $ERR_FILE
    log "set_redhat_dhcp: ifup eth0 failed due to error: $(cat $ERR_FILE)...reloading from backup"
    # Restore from backup and exit
    ifdown eth0 > /dev/null 2>&1
    mv ${cfg}.bak $cfg
    ifup eth0 > /dev/null 2>&1
    echo "Unable to set DHCP network configuration." >&2
    exit 1
  fi

  rm -f ${cfg}.bak

  # 5) remove all other copies of /etc/resolv.conf
  for conf in "/etc/sysconfig/networking/profiles/default/resolv.conf ${resolv}.predhclient"
  do
    rm -f $conf
  done

  # Backup hosts
  cp /etc/hosts /etc/hosts.bak

  new_ip=$(get_ip)
  # Update the ipaddress associated with our hostname
  hn=$(get_hostname)

  log "set_redhat_dhcp: hosts old: $(cat /etc/hosts)"
  grep -E "^$old_ip" /etc/hosts > /dev/null
  if [ $? -eq 0 ]; then
    # Change the ip associated with the hostname to the new ip
    sed "s/\(^$old_ip\)\(\>\s*.*\<.*$\)/$new_ip\2/" /etc/hosts > /etc/hosts.new
    mv /etc/hosts.new /etc/hosts
  else
    # Add a line with the new ip and the existing hostname
    echo -e "$new_ip\t\t$hn" >> /etc/hosts
  fi
  log "set_redhat_dhcp: hosts new: $(cat /etc/hosts)"

  rm /etc/hosts.bak
}

check_rc() {
  rc=$?
  if [ $rc -ne 0 ]; then
    log "$1: Failed due to error: $(cat $ERR_FILE)"
  fi
  return $rc
}

stop_miqtop() {
  systemctl stop miqtop
}

stop_miqvmstat() {
  systemctl stop miqvmstat
}

stop_httpd() {
  systemctl stop httpd > /dev/null 2>> $ERR_FILE
}

stop_vmdb() {
  LOG_LINE='[----] I, ['`date -u`']  EVM SERVER STOP initiated by MIQ Console.' && echo $LOG_LINE >> $EVMLOG
  log "EVM SERVER STOP initiated by MIQ Console."
  systemctl stop  evmserverd >> $LOG_FILE 2>> $ERR_FILE
  check_rc "stop_vmdb"
  rc=$?

  if [ $rc -ne 0 ]; then
    return $rc
  fi

  sleep $VMDB_STOP_TIMER

  close_pid_fd $PIDFILE
  check_rc "close_pid_fd"
  return $?
}

close_pid_fd() {
  pid_file=$1
  if [ -f $pid_file ]; then
    pid=`cat $pid_file`
    log "close_pid_fd: closing open fd for pid: $pid"
    if [ -d "/proc/$pid/fd" ]; then
      # close all open file descriptors
      for FD in /proc/$pid/fd/*
      do
        FD=`basename $FD`

        if [ $FD -le 1 ]
        then
          continue
        fi

        log "close_pid_fd: Closing FD: $FD"

        eval "exec ${FD}>&-"
        eval "exec ${FD}<&-"
      done
      log "close_pid_fd: Open FDs"
      log "close_pid_fd: `lsof -p $pid`"

      while [ -f $pid_file ]
      do
        log "close_pid_fd: Sleeping for 5 seconds due to existance of: $pid_file"
        sleep 5
      done
      log "close_pid_fd: Safe to continue since $pid_file no longer exists"
    fi
  fi
}

start_vmdb(){
  LOG_LINE='[----] I, ['`date -u`']  EVM SERVER START initiated by MIQ Console.' && echo $LOG_LINE >> $EVMLOG
  log "EVM SERVER START initiated by MIQ Console."
  systemctl start evmserverd >> $LOG_FILE 2>> $ERR_FILE
  check_rc "start_vmdb"
}

restart_vmdb() {
  LOG_LINE='[----] I, ['`date -u`']  EVM SERVER RESTART initiated by MIQ Console.' && echo $LOG_LINE >> $EVMLOG && echo $LOG_LINE >> $LOG_FILE
  stop_vmdb
  start_vmdb
}

case $1 in
  -GET | -get)
    shift
    get_info "$@"
    ;;
  -DHCP | -dhcp)
    set_dhcp
    ;;
  -STATIC | -static)
    shift
    set_static "$@"
    ;;
  -HOST | -host)
    shift
    set_hostname "$@"
    ;;
  -TIMESERVER | -timeserver)
    shift
    set_timeserver "$@"
    ;;
  -RESTART | -restart)
    restart_vmdb
    ;;
  -RESTARTOS | -restartos)
    restart_os
    ;;
  -RESTARTOSRMLOGS | -restartosrmlogs)
    restart_os_rm_logs
    ;;
  -SEARCHORDER | -searchorder)
    shift
    set_search_order "$@"
    ;;
  -START | -start)
    shift
    start_vmdb
    ;;
  -STOP | -stop)
    shift
    stop_vmdb
    ;;
  -SHUTDOWN | -shutdown)
    shutdown_os
    ;;
  -TIME | -time)
    shift
    set_time "$@"
    ;;
  -TIMEZONE | -timezone)
    shift
    set_timezone "$@"
    ;;
  *)
    echo -e $USAGETEXT >&2
    exit 1
    ;;
esac

exit 0
