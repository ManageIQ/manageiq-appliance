#!/bin/bash
# description: ManageIQ SELinux Policy support

# The appliance needs an selinux policy to access sssd via dbus
if [ -z "`/sbin/semodule -l | grep '^init_dbus_sssd	'`" ]
then
  SMOD=/tmp/miq_init_dbus_sssd
  cat - >$SMOD.te <<!END!
module init_dbus_sssd 1.0;

require {
  type sssd_t;
  type initrc_t;
  class dbus send_msg;
}

#============= sssd_t ==============
allow sssd_t initrc_t:dbus send_msg;
!END!
  /usr/bin/checkmodule -M -m -o $SMOD.mod $SMOD.te
  /usr/bin/semodule_package -m $SMOD.mod -o $SMOD.pp
  /sbin/semodule -i $SMOD.pp
  rm -f $SMOD.te $SMOD.mod $SMOD.pp
fi
