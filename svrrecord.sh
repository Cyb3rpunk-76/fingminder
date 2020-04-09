#!/bin/bash

workdir=/home/pi/MEDIASERVER/motion/cameras
bindir=/home/pi/.bin
idcamera=$1
fileext=mp4
secinterval=60

123

while true; do
    WDTE=`date +%Y.%m.%d`
    HOUR=`date +%H~%M~%S`
    LANG=C WEEK=$(date +"%a")
    WDIR=$workdir"/"$WEEK
    IDIR=$WDIR"/IPC"$idcamera
    FFN=$WEEK"_"$WDTE"_"$HOUR"."$fileext
    FDIR=$IDIR"/"$FFN
    ADIR=$IDIR"/.dir.id"
    SDIR=$IDIR"/.shutdown.cmd"
    CDIR=$IDIR"/.current.id"
    LDIR=$workdir"/record.log"
    RMDIR=0
    if [ ! -d "$WDIR" ]; then
      mkdir "$WDIR"    
    fi
    if [ -d "$IDIR" ]; then
      if [ -e "$ADIR" ]; then
        if [ ! "$WDTE" == "$(cat $ADIR)" ];then
          rm $ADIR > /dev/null 2> /dev/null
          RMDIR=1
        fi
      else
        RMDIR=1
      fi
    else
      mkdir "$IDIR"
    fi
    if [ "$RMDIR" == "1" ];then
      echo "IPC "$idcamera" Diretorio '$IDIR' [REMOVIDO] `date +%Y.%m.%d` `date +%H:%M:%S`" >> $LDIR
      rm -rf $IDIR > /dev/null 2> /dev/null
    fi
    if [ ! -d "$WDIR" ]; then
      mkdir $WDIR > /dev/null 2> /dev/null
    fi
    if [ ! -d "$IDIR" ]; then
      mkdir $IDIR > /dev/null 2> /dev/null
    fi
    echo "$FFN" > $CDIR
    source $bindir/makelivevideo.sh "$secinterval" "$idcamera" 0 "$FDIR" > /dev/null 2> /dev/null
    if [ ! -e "$ADIR" ]; then
      echo "$WDTE" > $ADIR
    fi
    if [ -e "$SDIR" ]; then
      echo "IPC "$idcamera" [FORCED SHUTDOWN] `date +%Y.%m.%d` `date +%H:%M:%S`" >> $LDIR
      rm $CDIR > /dev/null 2> /dev/null
      rm $SDIR > /dev/null 2> /dev/null
      break
    fi
done



#!/bin/sh
 
# -q quiet
# -c nb of pings to perform

#ping -q -c5 google.com > /dev/null
#ping -q -c1 google.com > /dev/null
 
#if [ $? -eq 0 ]
#then
# echo "ok"
#fi

#lastip=`cat lastip`
#echo Checking external IP ...
#curl -s http://ifconfig.me > lastip
#currentip=`cat lastip`


