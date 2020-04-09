# --------------------------------------------------------
# remotecomm.sh = make a interface to use telegram
# daemon to receive commands by admin
#
# Darney Lampert - 2018-02-23
# --------------------------------------------------------
#!/bin/bash

bindir="/home/pi/.bin"
cd $bindir
. ./bin.fnc
. ./tele_emojis.fnc

tmpfile=$(mktemp /tmp/telegram-text-temp.XXXXXX)
rmfile_ifexist $tmpfile
comm_found=0

if [ -f "$bindir/cmds/$1.sh" ]; then
  $bindir/cmds/$1.sh $tmpfile $* &
  comm_found=1
fi

if [ "$comm_found" -ne "1" ]; then
  ./remoteal.sh "$1" &
fi

exit 0
