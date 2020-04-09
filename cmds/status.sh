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
unitname="status"
mkdir_ifnote $bindir"/cmds/.tmp" 770
tmpfile_use=$bindir"/cmds/.tmp/"$unitname
strdiv=""
sleep 1
rmfile_ifexist $tmpfile_use
#for i in {1..14}; do strdiv="$strdiv""$emoji_hifen"; done
for i in {1..40}; do strdiv="$strdiv""_"; done
printf "$strdiv\n" >> $tmpfile_use
printf "$(echo $info_hostname | awk '{print toupper($0)}') $info_so" >> $tmpfile_use
printf "\n$emoji_chrono Up Time: $info_uptime\n" >> $tmpfile_use
printf "$strdiv\n" >> $tmpfile_use
printf "$emoji_valve CPU: $info_cpu (x4)\n" >> $tmpfile_use
# CPU Temperature
strdiv=""
tempp=$(expr $info_cpu_temp - 200)
tempperc=$(round $(math "100*$tempp/650") 1)
tempcelc=$(round $(math "$info_cpu_temp/10") 1)
tempbloc=$(round $(math "14*$tempp/650") 0)
printf "$emoji_temper CPU Temp.: $tempcelcºC (max 85ºC)\n" >> $tmpfile_use
for i in {1..14}; do
  if [ "$i" -gt "$tempbloc" ]; then
    strdiv="$strdiv""$emoji_emptyblock"
  else
    strdiv="$strdiv""$emoji_fullblock"
  fi; done
printf "$strdiv\n" >> $tmpfile_use
# GPU Temperature
strdiv=""
tempp=$(expr $info_gpu_temp - 200)
tempperc=$(round $(math "100*$tempp/650") 1)
tempcelc=$(round $(math "$info_gpu_temp/10") 1)
tempbloc=$(round $(math "14*$tempp/650") 0)
printf "$emoji_temper GPU Temp.: $tempcelcºC (max 85ºC)\n" >> $tmpfile_use
strdiv=""
for i in {1..14}; do
  if [ "$i" -gt "$tempbloc" ]; then
    strdiv="$strdiv""$emoji_emptyblock"
  else
    strdiv="$strdiv""$emoji_fullblock"
  fi; done
printf "$strdiv\n" >> $tmpfile_use
strdiv=""
#for i in {1..14}; do strdiv="$strdiv""$emoji_hifen"; done
for i in {1..40}; do strdiv="$strdiv""_"; done
printf "$strdiv\n" >> $tmpfile_use
printf "$emoji_valve Storage devices:\n" >> $tmpfile_use
while read line; do
  hdsize=$(echo "$line" | awk '{print $3}')
  hdsize=$(echo "${hdsize//(}")
  hdsize=$(echo "${hdsize//%}")
  hdsize=$(round $(math "14*$hdsize/100") 0)
  echo "$emoji_storage $line"  >> $tmpfile_use
  strdiv=""
  for i in {1..14}; do
    if [ "$i" -gt "$hdsize" ]; then
      strdiv="$strdiv""$emoji_emptyblock"
    else
      strdiv="$strdiv""$emoji_fullblock"
    fi; done
  printf "$strdiv\n" >> $tmpfile_use
done < <(df -H | awk 'substr($1,1,5)=="/dev/"{print $1" "$2" ("$5" Used)"}')
strdiv=""
#for i in {1..14}; do strdiv="$strdiv""$emoji_hifen"; done
for i in {1..40}; do strdiv="$strdiv""_"; done
printf "$strdiv\n" >> $tmpfile_use
while read line; do
  mem=$(echo "$line" | awk '{print $1}')
  memsize1=$(echo "$line" | awk '{print $2}')
  memsize2=$(echo "$line" | awk '{print $3}')
  memperc=$(round $(math "100*$memsize2/$memsize1") 0)
  memblock=$(round $(math "14*$memsize2/$memsize1") 0)
  echo "$emoji_memory $mem  "$memsize1"Mb ($memperc% Used)"  >> $tmpfile_use
  strdiv=""
  for i in {1..14}; do
    if [ "$i" -gt "$memblock" ]; then
      strdiv="$strdiv""$emoji_emptyblock"
    else
      strdiv="$strdiv""$emoji_fullblock"
    fi; done
  printf "$strdiv\n" >> $tmpfile_use
done < <(free --mega -w | sed -n '1!p')
strdiv=""
#for i in {1..14}; do strdiv="$strdiv""$emoji_hifen"; done
for i in {1..40}; do strdiv="$strdiv""_"; done
printf "$strdiv\n" >> $tmpfile_use

source $bindir/tele.sh send_text "$adminnick" "$tmpfile_use"
rmfile_ifexist $tmpfile_use

exit 0
