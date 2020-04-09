#!/bin/bash

unitname="run_hdext_check"
workpath=`pwd`/

function run_hdext_check {
  CURRENT_HDEXT_OWNER_USER="`ls -ld /home/pi/MEDIASERVER | awk '{print $3}'`"
  if [ "$CURRENT_HDEXT_OWNER_USER" != "pi"  ]; then
    sudo umount UUID=5394-E1FB
    mount UUID=5394-E1FB
  fi
  return 0
}

run_hdext_check

exit 0