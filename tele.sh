#!/bin/bash

tgpath=/home/pi/tg
netcat_wait=2
deamon_port=8833
deamon_host=localhost
tele_cmd=$1
tele_dest=$2
tele_body=$3
cd $tgpath
timeout -k 120 120 \
netcat -q$netcat_wait \
       $deamon_host \
       $deamon_port \
       echo \
       <<< "$tele_cmd $tele_dest $tele_body" &

exit 0
