#!/bin/sh

### Description: miqvmstat starts vmstat(1) sending output to /var/www/miq/vmdb/log/vmstat_output.log` ###

LOG_DIR=/var/www/miq/vmdb/log
PID_DIR=/var/www/miq/vmdb/tmp/pids

LOG_FILE=${LOG_DIR}/vmstat_output.log
PID_FILE=${PID_DIR}/vmstat.pid

### Attempt to create pid and log directores in case they do not exist ###
mkdir -p ${PID_DIR}
mkdir -p ${LOG_DIR}
chown ${USER}:${USER} ${PID_DIR} ${LOG_DIR}

### If an instance of vmstat(1) in running, do not start another. ###
if [ -e ${PID_FILE} ]
then
	PID=`cat ${PID_FILE}`
	ps -p $PID
	if [ $? -eq 0 ]
	then
		echo "miqvmstat: vmstat already started $PID"
		exit 1
	else
		### PID file exists but process is dead, delete the PID file ###
		rm -f ${PID_FILE}
	fi
fi

echo "miqvmstat: start: date time is-> $(date) $(date +%z)" >> ${LOG_FILE}
vmstat -a -n 60 >> ${LOG_FILE} 2>&1 &
echo $! >> ${PID_FILE}
