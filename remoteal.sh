#!/bin/bash

bindir="/home/pi/.bin"
cd $bindir
. ./tele_emojis.fnc

sleep 1
./tele.sh msg $adminnick "$emoji_stop  command '$1' not implemented yet..."
echo "$1" >> $bindir/out.txt

exit 0
