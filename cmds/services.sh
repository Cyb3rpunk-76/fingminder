#!/bin/bash

bindir="/home/pi/.bin"
source $bindir/bin.fnc
source $bindir/tele_emojis.fnc
source $bindir/rbi_info.fnc
unitname="services"
mkdir_ifnote $bindir"/cmds/.tmp" 770
tmpfile_use=$bindir"/cmds/.tmp/"$unitname
strdiv=""
rmfile_ifexist $tmpfile_use
for i in {1..40}; do strdiv="$strdiv""_"; done
printf "$strdiv\n" >> $tmpfile_use
printf "$(echo $info_hostname | awk '{print toupper($0)}') $info_so" >> $tmpfile_use
printf "\n$emoji_chrono Up Time: $info_uptime\n" >> $tmpfile_use
printf "$strdiv\n" >> $tmpfile_use
printf "$emoji_valve Services status:\n" >> $tmpfile_use
while read line; do
  serstatus=$(echo "$line" | awk '{print $1}')
  serstatus=$( [[ "$serstatus" =~ [-?] ]] && echo "$emoji_redcircle_minus" || echo "$emoji_ok" )
  servicenam=$(echo "$line" | awk '{print $2}')
  echo "$serstatus $servicenam" >> $tmpfile_use
done < <(service --status-all | awk '{print $2" "$4}')
strdiv=""
for i in {1..40}; do strdiv="$strdiv""_"; done
printf "$strdiv\n" >> $tmpfile_use

source $bindir/tele.sh send_text "$adminnick" "$tmpfile_use"
rmfile_ifexist $tmpfile_use

exit 0
