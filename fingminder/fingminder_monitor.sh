#!/bin/bash

# ------------------------------------------------------------------
# fingminder_monitor.sh = start "FING" processes to scan network,
# wait a CSV file to import on database.
#
# Darney Lampert, 2018-02-19
# ------------------------------------------------------------------

cd /home/pi/.bin/fingminder

if [ "$(whoami)" = "root" ]; then
  echo "root user detected... exiting." >> ./log.txt 
  exit 1
fi

source dbase.fnc
source ../bin.fnc

unitname="fingminder_monitor"
workpath=/home/pi/.bin/fingminder/
flagstop="$workpath"stop
readarray network_areas < "$workpath"subnets.cnf

function load_network_areas {
  count_nareas=0
  while [ "x${network_areas[count_nareas]}" != "x" ]
  do
    narea=(${network_areas[count_nareas]} $count_nareas 0)
    network_areas[$count_nareas]=${narea[*]}
    count_nareas=$(( $count_nareas + 1 ))
  done
  return 0
}

function stop_fing_engine {
  count_nareas=0
  while [ "x${network_areas[count_nareas]}" != "x" ]
  do
    narea=(${network_areas[count_nareas]})
    if [ ${narea[2]} -gt 0 ];then
      sudo kill -9 ${narea[2]} 2> /dev/null > /dev/null
    fi
    count_nareas=$(( $count_nareas + 1 ))
  done
  sudo pkill -9 fing.bin 2> /dev/null > /dev/null
  mkdir_ifnote "$workpath"out 755
  rm -f "$workpath"out/* 2> /dev/null > /dev/null
  return 0
}

function start_fing_engine {
  stop_fing_engine
  count_nareas=0
  while [ "x${network_areas[count_nareas]}" != "x" ]
  do
    narea=(${network_areas[count_nareas]})
    narea[1]=$count_nareas
    sudo fing ${narea[0]} -o table,csv,"$workpath"out/scanh_${narea[1]}.csv 2> /dev/null > /dev/null &
    narea[2]=$!
    network_areas[$count_nareas]=${narea[*]}
    count_nareas=$(( $count_nareas + 1 ))
  done
  return 0
}

function start_monitor {
  while :
  do
    count_nareas=0
    while [ "x${network_areas[count_nareas]}" != "x" ]
    do
      narea=(${network_areas[count_nareas]})
      csvfile="$workpath"out/scanh_${narea[1]}.csv
      if [ -e $csvfile ]; then
        ./fingminder_sqlimport.sh $csvfile ${narea[0]}
      fi
      count_nareas=$(( $count_nareas + 1 ))
    done
    if [ -e $flagstop ]; then
      stop_fing_engine
      rm -f $flagstop 2> /dev/null > /dev/null
      exit 0
    fi
    count_srvcs=0
    while [ "x${tasklist[count_srvcs]}" != "x" ]
    do
      taskp=(${tasklist[count_srvcs]})
      if [ -f ./${taskp[0]} ]; then
        taskp[2]=$(( ${taskp[2]} + 1 ))
        if [ ${taskp[2]} -gt ${taskp[1]} ]; then
          taskp[2]=0
          # echo ${taskp[0]} - `date '+%Y.%m.%d %H:%M:%S'` - ${taskp[1]} >> ./logxx.txt
          ./${taskp[0]} &
        fi
        tasklist[$count_srvcs]=${taskp[*]}
      fi
      count_srvcs=$(( $count_srvcs + 1 ))
    done
    sleep 1
  done
  return 0
}

cd $workpath

load_network_areas

tasklist=(
     'zmevent_monitor.sh 10 0'
     'services_monitor.sh 1200 0'
     'notify_monitor.sh 15 0'
     'wifi_monitor.sh 900 0'
     'run_hdext_check.sh 15 0'
   )

./service_start.sh

start_fing_engine

start_monitor

exit 0