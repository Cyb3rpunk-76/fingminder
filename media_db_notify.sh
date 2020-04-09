#!/bin/bash

# ------------------------------------------------------------------
# Darney Lampert, 2020-01-05
# Grava no mysql, arquvios de media gerados pelo raspberry
# ------------------------------------------------------------------

if [ "$(whoami)" = "root" ]; then
  echo "root user detected... exiting."
  exit 1
fi

mediadevice="${1}"
mediafile="${2}"
mediaformat="${3}"
mediawhen="${4/_/ }"
bindir="/home/pi/.bin"
unitname="media_db_notify"
workpath=`pwd`/
source "${bindir}/fingminder/dbase.fnc"
source "${bindir}/bin.fnc"
mysql --host=$DB_HOST \
      --user=$DB_USER \
      --password=$DB_PASSWD \
      $DB_NAMEBASE \
      -e "call sp_notify_newmedia('${mediadevice}','${mediaformat}','${mediawhen}','${mediafile}');" 
exit 0