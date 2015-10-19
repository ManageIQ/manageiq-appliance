#!/bin/bash

curl -ILf --connect-timeout 2 http://169.254.169.254/2009-04-04/meta-data
[ "$?" = "0" ] && echo "datasource_list: [ Ec2, None ]" > /etc/cloud/cloud.cfg.d/datasources.cfg && exit 0

curl -ILf --connect-timeout 2 http://169.254.169.254/openstack/latest/meta_data.json
[ "$?" = "0" ] && echo "datasource_list: [ OpenStack, None ]" > /etc/cloud/cloud.cfg.d/datasources.cfg && exit 0

gateway=`route -n | grep "^0\.0\.0\.0.*" | awk '{print $2}'`
curl -ILf --connect-timeout 2 "http://$gateway/latest/meta-data"
[ "$?" = "0" ] && echo "datasource_list: [ CloudStack, None ]" > /etc/cloud/cloud.cfg.d/datasources.cfg && exit 0

echo "datasource_list: [ NoCloud, ConfigDrive, AltCloud, None ]" > /etc/cloud/cloud.cfg.d/datasources.cfg
