#!/bin/bash

raspberryhd="/home/pi/MEDIASERVER/motion/cameras"
outputfile_Temp_AL=""
outputfile_Temp_AS=""
outputfile_Temp_AR=""
outputfileerr=""
outputfile_Temp=""

round() {
    printf "%.$2f" $(echo "scale=2;$1" | bc | sed 's/[.]/,/')
}

math() {
    echo "$*" | bc -l
}

apagararquivostemps() {
    if [ -e "$outputfileerr" ]; then
        rm -rf "$outputfileerr" > /dev/null 2> /dev/null
    fi
    if [ -e "$outputfile_Temp" ]; then
        rm -rf "$outputfile_Temp" > /dev/null 2> /dev/null
    fi
    if [ -e "$outputfile_Temp_AL" ]; then
        rm -rf "$outputfile_Temp_AL" > /dev/null 2> /dev/null
    fi
    if [ -e "$outputfile_Temp_AR" ]; then
        rm -rf "$outputfile_Temp_AR" > /dev/null 2> /dev/null
    fi
    if [ -e "$outputfile_Temp_AS" ]; then
        rm -rf "$outputfile_Temp_AS" > /dev/null 2> /dev/null
    fi
}

if [ -d /home/pi/ ]; then
  bindir="/home/pi/.bin"
else
  bindir="/home/darney/Dropbox/Linux/raspberry/bin"
fi

errorcode=0

if [ $# -lt 4 ]; then
   echo "Syntaxe : "$0" [Record duration # Seconds] [IP sufix #] [Streaming #] [Output video filename]"
   errorcode=1
else
  ipsufix=$2
  declare -a camerainfo=( $($bindir/ipcaminfo.sh $ipsufix) )
  if [ ${#camerainfo[@]} -lt 4 ]; then
     echo "Impossivel determinar dados da camera de sufixo '$ipsufix'"
     errorcode=1
  else   
    cameraengine="${camerainfo[3]}"
    iprecsecs=$1
    iprecsecslimit=$iprecsecs
    ((iprecsecslimit+=30))
    ipstraming=$3
    outputfile=$4
    ipcamera="${camerainfo[0]}"
    ipquando="`date +%Y-%m-%d_%H~%M~%S`"
    camname="${camerainfo[1]}"
    iptitle=$ipquando" - IPC."$camname"["$ipcamera"]"
    timeoutcmd="timeout -k $iprecsecslimit $iprecsecslimit"
    outputfinalfile=""
    reccmd=""
    reccmd_L=""
    reccmd_R=""
    recaudio=0
    if [ -d "$raspberryhd" ]; then
      outputfinalfile="$outputfile"
      LANG=C WEEK=$(date +"%a")
      outputfile="${raspberryhd}/IPC.${camname}_${WEEK}_${ipquando}.mp4"
      tmpdir="${raspberryhd}/tmp"
    else
      tmpdir="/tmp/lst_prt_svr"
    fi
    file_write_test="${tmpdir}/.file_write_to_test"
    if [ ! -e "$file_write_test" ]; then
        echo test > "$file_write_test" 2> /dev/null
    fi
    outputfileerr=$(dirname "${outputfile}")/".tmp_err_"$(basename "${outputfile}")
    outputfile_Temp=$(dirname "${outputfile}")/".tmp_"$(basename "${outputfile}")
    if [ -w "$file_write_test" ]; then
        case "$cameraengine" in
            1) reccmd="$timeoutcmd ffmpeg -y -t "$iprecsecs" -r 5 -i ${camerainfo[2]} -vcodec copy -metadata title=\""$iptitle"\" -map 0 -r 5 -f mp4 \""$outputfile"\" "
                ;;
            2) reccmd="$timeoutcmd ffmpeg -y -t "$iprecsecs" -r 5 -i ${camerainfo[2]} -vcodec copy -metadata title=\""$iptitle"\" -an -map 0 -r 5 -f mp4 \""$outputfile"\" "
            declare -a cameraL=( $($bindir/ipcaminfo.sh 80) ) # som da rua
            declare -a cameraR=( $($bindir/ipcaminfo.sh 82) ) # som de dentro de casa
            outputfile_Temp_AS=$(dirname "${outputfile}")/".tmp_AS_"$(basename "${outputfile}" .mp4).mp3
            outputfile_Temp_AL=$(dirname "${outputfile}")/".tmp_AL_"$(basename "${outputfile}" .mp4).mp3
            outputfile_Temp_AR=$(dirname "${outputfile}")/".tmp_AR_"$(basename "${outputfile}" .mp4).mp3
            reccmd_L="$timeoutcmd ffmpeg -y -t "$iprecsecs" -i ${cameraL[2]} -vn -q:a 0 -map a -f mp3 \""$outputfile_Temp_AL"\" "
            reccmd_R="$timeoutcmd ffmpeg -y -t "$iprecsecs" -i ${cameraR[2]} -vn -q:a 0 -map a -f mp3 \""$outputfile_Temp_AR"\" "
            echo $reccmd_L
            echo $reccmd_R
            echo $outputfile_Temp_AL
            echo $outputfile_Temp_AR
            echo $outputfile_Temp_AS
                ;;
        esac
        if [ "$errorcode"="0" ]; then
            if [ -e "$outputfile" ]; then
                rm -rf "$outputfile" > /dev/null 2> /dev/null
            fi
            apagararquivostemps
            pids=()
            eval $reccmd 2> $outputfileerr > /dev/null &
            pids+=($!)
            if [ ! -z "$reccmd_L" ]; then
                eval $reccmd_L 2> /dev/null > /dev/null &
                pids+=($!)
                eval $reccmd_R 2> /dev/null > /dev/null &
                pids+=($!)
            fi
            wait "${pids[@]}"
            if [ -e "$outputfile" ]; then
                naudios=0       
                if [ ! -z "$reccmd_L" ]; then
                    if [ -e "$outputfile_Temp_AL" ]; then
                        ((naudios+=1))
                    fi
                    if [ -e "$outputfile_Temp_AR" ]; then
                        ((naudios+=1))
                        if [ $naudios -lt 2 ]; then 
                        outputfile_Temp_AL=$outputfile_Temp_AR                    
                        fi
                    fi
                    if [ ! $naudios -lt 1 ]; then
                        case "$naudios" in
                            2) ffmpeg -i "$outputfile_Temp_AL" -i "$outputfile_Temp_AR" -filter_complex "[0:a][1:a]join=inputs=2:channel_layout=stereo[a]" -map "[a]" "$outputfile_Temp_AS" 2> /dev/null > /dev/null
                            ;;
                            1) mv "$outputfile_Temp_AL" "$outputfile_Temp_AS" 2> /dev/null > /dev/null
                            ;;
                        esac
                        if [ -e "$outputfile_Temp_AS" ]; then
                            mv "$outputfile" "$outputfile_Temp" 2> /dev/null > /dev/null
                            ffmpeg -i "$outputfile_Temp" -i "$outputfile_Temp_AS" -c:v copy -c:a aac -b:a 64k -strict -2 "$outputfile" 2> /dev/null > /dev/null
                        fi
                    fi     
                fi      
                if [ -e "$outputfile" ]; then
                    if [ ! -z "$outputfinalfile" ]; then
                        cp "$outputfile" "$outputfinalfile" 2> /dev/null > /dev/null
                    fi
                    errorcode=0
                    ${bindir}/media_db_notify.sh ${ipcamera} ${outputfile} mp4 ${ipquando} &
                else    
                    errorcode=1
                fi    
            else
                echo $(tail -n 1 $outputfileerr) | rev | cut -d':' -f 1 | rev
                errorcode=1
            fi
            apagararquivostemps
        fi
    else
        errorcode=2
    fi
  fi
  if [ -d /home/pi/ ]; then
      if [ ! $errorcode -lt 1 ]; then
          timeout -k 1000 1000 $bindir/tele.sh msg "$adminnick" "$emoji_stop Nao foi possivel gravar o video da camera "$iptitle", arquivo "$outputfile &
      fi    
  fi  
fi
