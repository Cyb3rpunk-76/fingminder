#!/bin/bash

round() {
    printf "%.$2f" $(echo "scale=2;$1" | bc | sed 's/[.]/,/')
}

math() {
    echo "$*" | bc -l
}

if [ -d /home/pi/ ]; then
  bindir="/home/pi/.bin"
else
  bindir="/home/darney/Dropbox/Linux/raspberry/bin"
fi

errorcode=0

if [ $# -lt 1 ]; then
   errorcode=1
else
  ipsufix=$1
  cameraengine=0
  ipcport=554
  ipprefix="10.10.10."
  ipstraming=0
  ipcamera="$ipprefix""$ipsufix"
  camname="$($bindir/ipcamname.sh $ipsufix)"
  case "$ipsufix" in
    80|82) cameraengine=1
        ;;
    81|83|84|85) cameraengine=2
        ;;
    *)  errorcode=1
        ;;
  esac
  case "$cameraengine" in
    1)  ipuser=admin
        ipuserpass=$(cat ~/.bin/.pw/ipcam.key)
        ;;
    2)  ipuser=admin
        ipuserpass=$(cat ~/.bin/.pw/ipcam.key)
        ;;
    *)  errorcode=1
        ;;
  esac
  case "$cameraengine" in
    1) reccmd="rtsp://"$ipuser":"$ipuserpass"@"$ipcamera":"$ipcport"/onvif1"
        ;;
    2) reccmd="rtsp://"$ipuser":"$ipuserpass"@"$ipcamera":"$ipcport"/user="$ipuser"_password="$ipuserpass"_channel=1_stream="$ipstraming".sdp"
        ;;
  esac
fi
if [ $errorcode -lt 1 ]; then
  printf "%s\n" "$ipcamera"
  printf "%s\n" "$camname"
  printf "%s\n" "$reccmd"
  printf "%s\n" "$cameraengine"
else
  echo ""
fi
