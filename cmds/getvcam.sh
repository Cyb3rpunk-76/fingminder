#!/bin/bash

round() {
    printf "%.$2f" $(echo "scale=2;$1" | bc | sed 's/[.]/,/')
}

math() {
    echo "$*" | bc -l
}


bindir="/home/pi/.bin"
source $bindir/bin.fnc
source $bindir/tele_emojis.fnc
source $bindir/rbi_info.fnc
unitname="getvcam"
mkdir_ifnote $bindir"/cmds/.tmp" 770
tmpfile_use=$bindir"/cmds/.tmp/ipcam"$5.mp4
tmpfile_use_err=$bindir"/cmds/.tmp/ipcam"$5.mp4.err
rmfile_ifexist $tmpfile_use
rmfile_ifexist $tmpfile_use_err
source $bindir/makelivevideo.sh "$4" "$5" "$6" "$tmpfile_use" > "$tmpfile_use_err"
if [ -e "$tmpfile_use" ]; then
  if [ -e "$tmpfile_use_err" ]; then
    rm -rf "$tmpfile_use_err" > /dev/null 2> /dev/null
  fi
  source $bindir/tele.sh send_video "$adminnick" "$tmpfile_use"
  echo $bindir/tele.sh send_video "$adminnick" "$tmpfile_use"
  exit 0
else
  erromsg=$(cat $tmpfile_use_err)
  source $bindir/tele.sh msg "$adminnick" "$emoji_warning Error:$erromsg"
  echo $bindir/tele.sh msg "$adminnick" "$emoji_warning Error:$erromsg"
  sleep 2
#  rm -rf "$tmpfile_use_err" > /dev/null 2> /dev/null
  exit 1
fi
exit 0
