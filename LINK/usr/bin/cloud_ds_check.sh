#!/bin/bash
datasource_cfg=/etc/cloud/cloud.cfg.d/30_miq_datasources.cfg

curl -ILf --connect-timeout 2 --max-time 5 http://169.254.169.254/2009-04-04/meta-data
[ "$?" = "0" ] && echo "datasource_list: [ Ec2, None ]" > $datasource_cfg && exit 0

curl -ILf --connect-timeout 2 --max-time 5 http://169.254.169.254/openstack/latest/meta_data.json
[ "$?" = "0" ] && echo "datasource_list: [ OpenStack, None ]" > $datasource_cfg && exit 0

gateway=`route -n | grep "^0\.0\.0\.0.*" | awk '{print $2}'`
curl -ILf --connect-timeout 2 --max-time 5 "http://$gateway/latest/meta-data"
[ "$?" = "0" ] && echo "datasource_list: [ CloudStack, None ]" > $datasource_cfg && exit 0

echo "datasource_list: [ NoCloud, ConfigDrive, AltCloud, None ]" > $datasource_cfg
