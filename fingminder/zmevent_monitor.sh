#!/bin/bash

# ------------------------------------------------------------------
# zmevent_monitor.sh = search new events on zoneminder that need 
# notification.
#
# Darney Lampert, 2018-02-19
# ------------------------------------------------------------------

source ../bin.fnc
source dbase.fnc

unitname="zmevent_monitor"
workpath=`pwd`/
ctrlpath=$workpath"ctrl"
pidfile=$ctrlpath/$unitname.pid
csvfile=/tmp/$OS_USER/mdb/zm-events.csv

mkdir_ifnote /tmp 770
mkdir_ifnote $ctrlpath 770
mkdir_ifnote /tmp/$OS_USER 770
mkdir_ifnote /tmp/$OS_USER/mdb 770
rmfile_ifexist $csvfile
currpid=0
if [ -f $pidfile ]; then
  currpid=`cat $pidfile`
fi
if [ "$currpid" -gt "0" ]; then
  if [ "`ps -p $currpid -o comm=`" = "run_zmevent.sh" ]; then
    exit 2
  else
    currpid=0
  fi
fi
if [ "$currpid" -gt "0" ]; then
  exit 1
fi
mysql --host=$DB_HOST --user=$DB_USER --password=$DB_PASSWD $DB_ZMBASE -e " \
  SELECT \
         Id, \
         MonitorId, \
         REPLACE(Name,' ','~'), \
         REPLACE(Cause,' ','~'), \
         REPLACE(StartTime,' ','~'), \
         REPLACE(EndTime,' ','~'), \
         Emailed, \
         REPLACE(Notes,' ','~') \
  FROM Events \
  WHERE Emailed = 0 \
    AND EndTime is not null \
  INTO OUTFILE '$csvfile' \
  FIELDS TERMINATED BY ' ' \
  LINES TERMINATED BY '\n';"

if [ -f $csvfile ]; then
  IDSEP=""
  IDLIST=""
  while read pline; do
    IDLIST="$IDLIST$IDSEP$(echo $pline| cut -d' ' -f 1)"
    IDSEP=","
  done <$csvfile
  if ! [[ -z "$IDLIST" ]]
  then
    mysql --host=$DB_HOST --user=$DB_USER --password=$DB_PASSWD $DB_ZMBASE -e "UPDATE Events SET Emailed = 1 WHERE Id In ( $IDLIST );"
  fi
fi

./run_zmevent.sh $csvfile $pidfile &
echo $! > $pidfile

exit 0