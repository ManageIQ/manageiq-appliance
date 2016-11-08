#!/bin/bash

OLD_PG_NAME="rh-postgresql94"
NEW_PG_NAME="rh-postgresql95"

OLD_PG_PACKAGE="${OLD_PG_NAME}-postgresql"
NEW_PG_PACKAGE="${NEW_PG_NAME}-postgresql"

OLD_PG_SERVICE="${OLD_PG_NAME}-postgresql.service"
NEW_PG_SERVICE="${NEW_PG_NAME}-postgresql.service"

OLD_PGSQL_DIR="/var/opt/rh/${OLD_PG_NAME}/lib/pgsql"
NEW_PGSQL_DIR="/var/opt/rh/${NEW_PG_NAME}/lib/pgsql"

PG_LV_DEV="/dev/mapper/vg_data-lv_pg"

# sanity checks

# run as root
if [ "$(whoami)" != "root" ]
then
  echo "This script must be run as root"
  exit 1
fi

# make sure both versions of postgresql are installed
yum list installed ${OLD_PG_PACKAGE} &> /dev/null
if [ $? -ne 0 ]
then
  echo "${OLD_PG_PACKAGE} must be installed to upgrade, exiting."
  exit 1
fi

yum list installed ${NEW_PG_PACKAGE} &> /dev/null
if [ $? -ne 0 ]
then
  echo "${NEW_PG_PACKAGE} must be installed to upgrade, exiting."
  exit 1
fi

# make sure neither postgres service is running
systemctl stop ${OLD_PG_SERVICE}
systemctl stop ${NEW_PG_SERVICE}

# TODO these two checks should point the the correct mount point for future versions (remove the /data from the checks)
# make sure the old data directory is a mount point
mountpoint -q ${OLD_PGSQL_DIR}/data
if [ $? -ne 0 ]
then
  echo "$OLD_PGSQL_DIR/data is not a mount point, exiting."
  exit 1
fi

# make sure our postgres lv is mounted at the old data directory
if [ "$(mount | grep ${PG_LV_DEV} | cut -d' ' -f3)" != "$OLD_PGSQL_DIR/data" ]
then
  echo "$PG_LV_DEV is not mounted at $OLD_PGSQL_DIR/data, exiting."
  exit 1
fi

cat <<EOS
Upgrading PostgreSQL using this script is a destructive operation.
Please be sure to have backed up your cluster before upgrading.

EOS
read -p "Are you sure you want to proceed? (Y/N): " response
if [ "$response" != "Y" ]
then
  echo "Exiting."
  exit 1
fi

set -e

# fix mount point
# TODO this can be removed when the default mount point is pgsql, rather than the data directory
umount ${OLD_PGSQL_DIR}/data
mount ${PG_LV_DEV} ${OLD_PGSQL_DIR}
mkdir ${OLD_PGSQL_DIR}/data
# this will complain because of moving data into itself, but we're okay with that
mv ${OLD_PGSQL_DIR}/* ${OLD_PGSQL_DIR}/data || true

# create a directory for the new cluster
mkdir ${OLD_PGSQL_DIR}/data-new

# fix permissions
chown -R postgres ${OLD_PGSQL_DIR}/*
chgrp -R postgres ${OLD_PGSQL_DIR}/*
restorecon -R ${OLD_PGSQL_DIR}
chmod 0700 ${OLD_PGSQL_DIR}/data
chmod 0700 ${OLD_PGSQL_DIR}/data-new

# fix fstab
sed -i.bak -e "s=${OLD_PGSQL_DIR}/data=${NEW_PGSQL_DIR}=" /etc/fstab

# mount the volume at the new location
mount -a

# init the new cluster
su - postgres -c "initdb -D ${NEW_PGSQL_DIR}/data-new"

sed -i.bak -e "s/^#*shared_preload_libraries.*/shared_preload_libraries = 'pglogical'/" ${NEW_PGSQL_DIR}/data-new/postgresql.conf

# upgrade
su - postgres -c "source /opt/rh/${OLD_PG_NAME}/enable; /opt/rh/${NEW_PG_NAME}/root/usr/bin/pg_upgrade -b /opt/rh/${OLD_PG_NAME}/root/usr/bin -B /opt/rh/${NEW_PG_NAME}/root/usr/bin -d ${OLD_PGSQL_DIR}/data -D ${OLD_PGSQL_DIR}/data-new -k"

# copy conf files
cp ${OLD_PGSQL_DIR}/data/postgresql.conf ${OLD_PGSQL_DIR}/data-new
cp ${OLD_PGSQL_DIR}/data/pg_hba.conf ${OLD_PGSQL_DIR}/data-new
cp ${OLD_PGSQL_DIR}/data/pg_ident.conf ${OLD_PGSQL_DIR}/data-new

# remove old data directory
rm -rf ${OLD_PGSQL_DIR}/data

# move new data directory into place
mv ${NEW_PGSQL_DIR}/data-new ${NEW_PGSQL_DIR}/data

restorecon -R /var/opt/rh/${NEW_PG_NAME}
restorecon -R /opt/rh/${NEW_PG_NAME}

# unmount volume from old location
umount ${OLD_PGSQL_DIR}

systemctl disable ${OLD_PG_SERVICE}

cat <<EOS

The upgrade is complete

Before starting the new server, the following changes must be made to the postgresql.conf file:

 -checkpoint_segments = 15   # MIQ Value;
 -#checkpoint_segments = 3    # in logfile segments, min 1, 16MB each
 +#max_wal_size = 1GB
 +#min_wal_size = 80MB

 -shared_preload_libraries = 'pglogical'   # MIQ Value (change requires restart)
 +shared_preload_libraries = 'pglogical,repmgr_funcs'   # MIQ Value (change requires restart)

 +wal_log_hints = on

After making the changes, the server can be started using 'systemctl enable $NEW_PG_SERVICE && systemctl start $NEW_PG_SERVICE'
EOS
