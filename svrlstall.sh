#!/bin/bash

bindir="/home/pi/.bin"
source $bindir/bin.fnc
source $bindir/tele_emojis.fnc
source $bindir/rbi_info.fnc
unitname="svrlst"
mkdir_ifnote $bindir"/cmds/.tmp" 770
mkdir_ifnote $bindir"/cmds/.tmp/ipcam_alarm" 770
tmpfile_alarm=$bindir"/cmds/.tmp/ipcam_alarm_test.txt"
rmfile_ifexist $tmpfile_alarm

workhost=10.10.10.17
workport=$1

while true; do
  # rm $ADIR > /dev/null 2> /dev/null
  nc -n -w 2 -lv $workhost $workport > /dev/null 2> $tmpfile_alarm
  camid=$(tail -n 1 "$tmpfile_alarm" | cut -d' ' -f 3 | cut -d'.' -f 4)
  camid=${camid//]}
  case "$camid" in
    80|81|82|83|84|85)
      tmpfile_use=$bindir"/cmds/.tmp/ipcam_alarm/alarm"$camid".mp4"
      camname="$($bindir/ipcamname.sh $camid)"
      rmfile_ifexist $tmpfile_use
      source $bindir/tele.sh msg "$adminnick" """$emoji_warning Movimento detectado: "$camname" - Gravando "$emoji_check"""" &
      source $bindir/makelivevideo.sh 15 $camid 0 "$tmpfile_use" > /dev/null 2> /dev/null
      if [ -e "$tmpfile_use" ]; then
        source $bindir/tele.sh send_video "$adminnick" "$tmpfile_use" &
      else
        source $bindir/tele.sh msg "$adminnick" "$emoji_stop Houve erro ao gerar o video da movimentaçao em 10.10.10."$camid" ..." &
      fi
      sleep 2
  esac
done