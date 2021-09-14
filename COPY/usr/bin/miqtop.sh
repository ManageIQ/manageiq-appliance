#!/bin/sh

### Description: miqtop starts top(1) sending output to /var/www/miq/vmdb/log/top_output.log` ###

LOG_DIR=/var/www/miq/vmdb/log
PID_DIR=/var/www/miq/vmdb/tmp/pids

LOG_FILE=${LOG_DIR}/top_output.log
PID_FILE=${PID_DIR}/top.pid

### Attempt to create pid and log directores in case they do not exist ###
mkdir -p ${PID_DIR}
mkdir -p ${LOG_DIR}
chown ${USER}:${USER} ${PID_DIR} ${LOG_DIR}

### If an instance of top(1) in running, do not start another. ###
if [ -e ${PID_FILE} ]
then
	PID=`cat ${PID_FILE}`
	ps -p $PID
	if [ $? -eq 0 ]
	then
		echo "miqtop: top already started $PID"
		exit 1
	else
		### PID file exists but process is dead, delete the PID file ###
		rm -f ${PID_FILE}
	fi
fi

echo "miqtop: start: date time is-> $(date) $(date +%z)" >> ${LOG_FILE}
TERM=dumb COLUMNS=512 top -b -c -d 60 >> ${LOG_FILE} 2>&1 &
echo $! >> ${PID_FILE}
