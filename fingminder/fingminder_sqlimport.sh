#!/bin/bash

# ------------------------------------------------------------------
# fingminder_sqlimport.sh = load data from CSV file into database
# end call stored procedure.
#
# Darney Lampert, 2018-02-19
# ------------------------------------------------------------------

if [ "$(whoami)" = "root" ]; then
  echo "root user detected... exiting."
  exit 1
fi

source dbase.fnc
source ../bin.fnc

unitname="fingminder_sqlimport"
workpath=`pwd`/

function import_csv_dbase {
  mkdir_ifnote /tmp 770
  mkdir_ifnote /tmp/$OS_USER 770
  mkdir_ifnote /tmp/$OS_USER/mdb 770
  mkdir_ifnote "$workpath"logs 770
  netarea="$2"
  rmfile_ifexist /tmp/$OS_USER/mdb/network_live.csv
  cat "$1" | while read -r line ; do
    echo "$netarea;$line" >> /tmp/$OS_USER/mdb/network_live.csv
  done
  rm -f $1 2> /dev/null > /dev/null
  linfo1="$workpath"logs/sqlimport-"`date +%Y-%m-%d`".log
  echo "`date +%H:%M:%S` - Importing $netarea ..." >> $linfo1
  mysqlimport --fields-terminated-by=';' \
                         --host=$DB_HOST            \
                         --user=$DB_USER            \
                         --password=$DB_PASSWD      \
                         --columns=net_area,ip_address,lixo1,status,lixo2,hostname,mac_address,vendor \
                         --delete                   \
                         $DB_NAMEBASE               \
                         /tmp/$OS_USER/mdb/network_live.csv >> $linfo1
  mysql --host=$DB_HOST --user=$DB_USER --password=$DB_PASSWD $DB_NAMEBASE -e "call sp_net_live_monitor;"
  return 0
}

import_csv_dbase $1 $2

exit 0