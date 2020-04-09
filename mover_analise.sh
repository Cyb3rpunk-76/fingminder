#!/bin/bash

irmcount=0
ivdmove=0
ivdexist=0
ivdnovos=0
ivdtotal=0
sizerm=0
sizemove=0
sizeexist=0
sizetotal=0
sizenovos=0

obterpercentual() {
  echo "$(awk -v n="$1" -v y="$2" 'BEGIN{ print int((n/y)*100) }')%"
}

obterespacousado() {
  du -s /home/pi/MEDIASERVER | cut -f 1 2>> $operationslog
}

quandodt="`date +%Y-%m-%d`"
quandodth="`date +%Y-%m-%d\ %H:%M:%S`"
raspberryhd="/home/pi/MEDIASERVER/motion/cameras"
bindir="/home/pi/.bin"
tmpdir="${raspberryhd}/tmp"
weekagodir="${raspberryhd}/week1ago"
operationslog="${raspberryhd}/.log/L${quandodt}.log"
videomovelog="${raspberryhd}/.moveoldvideos.html"
videomovetab="${raspberryhd}/.moveoldvideos.tab"

declare -a fileworklist_last12hrs=( $(find $raspberryhd -maxdepth 1 -mmin -720 -type f) )
for file_to_proccess in "${fileworklist_last12hrs[@]}"; do
   filename=$(basename -- "${file_to_proccess}")
   extension="${filename##*.}"   
   if [ "$extension" == "mp4" ]; then
       cp "${file_to_proccess}" /home/pi/MEDIASERVER/motion/Requeridos/
   fi    
done
