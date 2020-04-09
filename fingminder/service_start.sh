#!/bin/bash

source dbase.fnc
source ../bin.fnc

unitname="service_start"
info_when=$(date +"%Y-%m-%d %H:%M:%S")
info_ip=`echo "$(hostname -I)" | awk '{print $1}'`
info_up=$(awk '{printf "%d", int($0) }' /proc/uptime)

if [ $info_up -lt 50 ];then
  info_up="True"
else
  info_up="False"
fi

function notify_start {
  mysql --host=$DB_HOST --user=$DB_USER --password=$DB_PASSWD $DB_NAMEBASE -e "call sp_service_monitor_start('$1',$2,'$3');"
  return 0
}

nc -w 2 -v $info_ip 3306 2> /dev/null > /dev/null
if [ $? -eq 1 ]; then
  sleep 40
fi

notify_start "$info_when" "$info_up" "$info_ip"

exit 0
