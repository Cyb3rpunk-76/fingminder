#!/bin/bash

alert_im=0
raspberryhd="/home/pi/MEDIASERVER/motion/cameras"
if [ -d /home/pi/ ]; then
  bindir="/home/pi/.bin"
  tmpdir="${raspberryhd}/tmp"
  alert_im=1
else
  bindir="/home/darney/Dropbox/Linux/raspberry/bin"
  tmpdir="/tmp/lst_prt_svr"
fi
source $bindir/bin.fnc
source $bindir/tele_emojis.fnc

declare -a cameraslist=( 
      "81"
      "83"
      "84"
      "85" )
      
workhost=$(hostname --all-ip-addresses | cut -d' ' -f 1)
unitname=${0}
tmpfile="${tmpdir}/output."
endcmdfile="${tmpdir}/.end.lst"
file_write_test="${tmpdir}/.file_write_to_test"

enviar_video() {
    case "$alert_im" in
        "1") source $bindir/tele.sh send_video "$adminnick" "${1}" &
        ;;
        *) notify-send "VIDEO ==" "${1}" &
        ;;
    esac
}

verificar_arquivos_antigos() {
    find "${tmpdir}" -mtime +2 -type f -delete  > /dev/null 2> /dev/null &
}

enviar_aviso() {
    case "$alert_im" in
        "1") source $bindir/tele.sh msg "$adminnick" "${1}" &
        ;;
        *) notify-send "Aviso de '${unitname}'" "${1}" &
        ;;
    esac
}

limpar_temporarios() {
    if [ -e "$endcmdfile" ]; then
        rm -rf "$endcmdfile" > /dev/null 2> /dev/null
    fi
}

gerar_evento_do_alerta() {
    camid="${1}"
    ipquando="`date +%Y-%m-%d_%H~%M~%S`"
    tmp_video_file="${tmpdir}/.tmp_${ipquando}_IPC_${camid}.mp4"
    if [ -e "$tmp_video_file" ]; then
        rm -rf "$tmp_video_file" > /dev/null 2> /dev/null
    fi
    declare -a camera_alerta=( $($bindir/ipcaminfo.sh $camid) )
    camname="${camera_alerta[1]}"
    enviar_aviso "${emoji_warning} Movimento detectado: ${camera_alerta[1]} - [Rec] ${emoji_check}"
    verificar_arquivos_antigos
    $bindir/makelivevideo.sh 25 $camid 0 "$tmp_video_file" > /dev/null 2> /dev/null
    if [ -e "$tmp_video_file" ]; then
        enviar_video "$tmp_video_file" 
    else
        enviar_aviso "${emoji_stop} Houve erro ao gerar o video de alerta ${camname} : 10.10.10.${camid} ..."
    fi
}

monitorar_shutdown() {
    declare -a pdis_to_kill=("${!1}")
    while true; do  
        if [ -e "$endcmdfile" ]; then
            for kpid_in in "${pdis_to_kill[@]}"; do
                kill -9 $kpid_in 2> /dev/null > /dev/null &
            done
            break
        fi
        sleep 1
    done  
}

ouvir_alerta_camera() {
    cam_alarm_port="19${1}"
    cam_temp_file="${tmpfile}${1}"
    while true; do  
        while true; do  
            nc -z "$workhost" "${cam_alarm_port}" 2> /dev/null > /dev/null
            if [ $? -lt 1 ]; then
                sleep 1
            else
                break
            fi
        done    
        nc -n -w 2 -lv "$workhost" "${cam_alarm_port}" > /dev/null 2> "${cam_temp_file}"
        cam_id=$(tail -n 1 "${cam_temp_file}" | cut -d' ' -f 3 | cut -d'.' -f 4)
        cam_id=${cam_id//]}
        if [ ! -z "$cam_id" ]; then
            if [ "$cam_id" == "21" ]; then
                cam_id="83"
            fi    
            if [ ! "$cam_id" == "${1}" ]; then 
                if [ ! "$cam_id" == "17" ]; then 
                    enviar_aviso "${emoji_stop} Aguardando por alerta de '${workhost}:${cam_alarm_port}', equipamento incorreto: '10.10.10.${cam_id}' "
                fi    
            else
                gerar_evento_do_alerta "${1}"
            fi
        fi    
    done  
}


sleep 30
if [ ! -d "$tmpdir" ]; then
    mkdir "$tmpdir" 2> /dev/null > /dev/null
fi
if [ ! -e "$file_write_test" ]; then
    echo test > "$file_write_test" 2> /dev/null
fi
if [ ! -w "$file_write_test" ]; then
    $bindir/pi_startup
fi    

limpar_temporarios

pids=()
for camera_id_in in "${cameraslist[@]}"; do
   ouvir_alerta_camera "$camera_id_in" &
   pids+=($!)
done
monitorar_shutdown pids[@] &
sspid=$!

wait "${pids[@]}"

timeout -k 1000 1000 kill -9 $sspid 2> /dev/null > /dev/null
limpar_temporarios
echo ""
echo "Bye"
killall $unitname 2> /dev/null > /dev/null

