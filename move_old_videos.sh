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

echo "" >> $operationslog
echo "--[ Inicio ]----------------: ${quandodth} " >> $operationslog
echo "" >> $operationslog

echo "<!DOCTYPE html><html><head><style>table {font-family: arial, sans-serif; border-collapse: collapse; width: 100%;} td, th { border: 1px solid #dddddd; text-align: left; padding: 2px;} tr:nth-child(even) {background-color: #dddddd;} " > $videomovelog
echo " #myProgress { width: 100%; background-color: #ddd; } #myBar { width: 1%; height: 15px; background-color: #296cd8; } #tdxr { text-align:right; padding-right: 10px; } div.a { text-align: left; margin-left: 100px; line-height: normal; } </style> </head> <body>" >> $videomovelog

quandoini="`date +%H:%M:%S`"

if [ ! -d "$weekagodir" ]; then
    mkdir "$weekagodir" 2>> $operationslog > /dev/null
fi

declare -a fileworklist_last12hrs=( $(find $raspberryhd -maxdepth 1 -mmin -720 -type f) )
for file_to_proccess in "${fileworklist_last12hrs[@]}"; do
   filename=$(basename -- "${file_to_proccess}")
   extension="${filename##*.}"   
   if [ "$extension" == "mp4" ]; then
       filesize=$(stat -c%s "${file_to_proccess}")
       filesizekb=$(bc <<< "scale=2; ${filesize}/1024")
       quando=$(stat -c %y "${file_to_proccess}" | cut -d'.' -f1)
       ((sizenovos+=filesize))
       ((ivdnovos+=1))
   fi    
done

declare -a fileworklist_1week=( $(find $raspberryhd -maxdepth 1 -mtime +7 -type f) )
for file_to_proccess in "${fileworklist_1week[@]}"; do
   quando="`date +%Y-%m-%d\ %H:%M:%S`"
   filename=$(basename -- "${file_to_proccess}")
   extension="${filename##*.}"   
   if [ "$extension" == "mp4" ]; then
     if [ -e "${file_to_proccess}" ]; then
       filesize=$(stat -c%s "${file_to_proccess}" 2>> $operationslog)
       filesizekb=$(bc <<< "scale=2; ${filesize}/1024")
       mv "${file_to_proccess}" "${weekagodir}/${file_to_proccess##*/}" 2>> $operationslog > /dev/null
       echo " == ${quando} - ${file_to_proccess##*/} ( ${filesizekb} Kb ) Movido para o dir [weekago] (+ de 7 dias)" >> $operationslog
     fi  
   fi    
done

declare -a fileworklist_2week=( $(find $weekagodir -maxdepth 1 -mtime +14 -type f) )
for file_to_proccess in "${fileworklist_2week[@]}"; do
   quando="`date +%Y-%m-%d\ %H:%M:%S`"
   filename=$(basename -- "${file_to_proccess}")
   extension="${filename##*.}"
   filesize=$(stat -c%s "${file_to_proccess}")
   filesizekb=$(bc <<< "scale=2; ${filesize}/1024")
   ((sizerm+=filesize))
   rm "${file_to_proccess}" 2>> $operationslog > /dev/null
   echo " == ${quando} - ${file_to_proccess##*/} ( ${filesizekb} Kb ) Excluido do dir [weekago] (+ de 14 dias)" >> $operationslog
   ((irmcount+=1))
done


quando="`date +%d.%m.%Y`"
quandofim="`date +%H:%M:%S`"
ivdmove="`ls -l ${weekagodir} | grep -v ^l | wc -l`"
ivdexist="`ls -l ${raspberryhd} | grep -v ^l | wc -l`"
sizeexist="`find ${raspberryhd} -maxdepth 1 -name "*.mp4" -ls | awk '{total += $7} END {print total}' 2>> $operationslog`"
sizemove="`find ${weekagodir} -maxdepth 1 -name "*.mp4" -ls | awk '{total += $7} END {print total}' 2>> $operationslog`"
sizegeralusado=$(obterespacousado)
((sizetotal=sizerm+sizemove+sizeexist))
((ivdtotal=ivdmove+ivdexist+irmcount))
LANG=C WEEK=$(date +"%a")

info_so="$(uname -o) $(uname -r)"
info_uptime=$(awk '{printf "%s Days, %02d:%02d:%02d", int($0/86400), int($0%86400/3600),int(($0%3600)/60),int($0%60) }' /proc/uptime)
info_cpu=$(uname -m)
info_cpu_temp=$(</sys/class/thermal/thermal_zone0/temp)
info_cpu_temp="$(bc <<< "scale=2; ${info_cpu_temp:1:3}/10")º"
info_hostname=$(uname -n)

echo "<img src=\"https://www.raspberrypi.org/app/uploads/2018/03/RPi-Logo-Reg-SCREEN.png\" alt=\"Powered by Raspberry Pi\" style=\"float:left; object-fit: contain; height:128px; width:160px;\">"  >> $videomovelog
echo "<div class=\"a\"><p><h2>Raspbian ${info_so}<br>Monitoramento do armazenamento - HD externo</h2></p><p><H3>${WEEK} ${quando}, Inicio: ${quandoini} - Fim: ${quandofim}</H3></p>"  >> $videomovelog
echo "<small>Uptime: ${info_uptime}<br>${info_hostname} - ${info_cpu} ( Temp.: ${info_cpu_temp} )</small></p></div><br>" >> $videomovelog

echo "<table> <caption><u><h3>Resumo dos arquivos de video</u></h3></caption> <tr> <th>Armazenamento dos videos</th> <th style=\"width:120px; text-align: center\">Arquivos de video</th> <th style=\"width:120px; text-align:center\">Tamanho</th> <th style=\"width:180px; text-align:center\">Tamanho total</th> <th id=\"tdxr\" style=\"width:80px;\">Uso%</th> <th style=\"width:200px;\"></th></tr>" >> $videomovelog
echo "<tr> <td>Total de Videos</td> <td id=\"tdxr\">${ivdtotal} videos</td> <td id=\"tdxr\">$(bc <<< "scale=2; ${sizetotal}/1024/1024/1024") Gb</td> <td id=\"tdxr\">(total hd em uso) $(bc <<< "scale=2; ${sizegeralusado}/1024/1024") Gb</td> <td id=\"tdxr\">$(obterpercentual $(bc <<< "scale=2; ${sizetotal}/1024") $sizegeralusado)</td> <td> <div id=\"myProgress\"><div id=\"myBar\" style=\"width:$(obterpercentual $(bc <<< "scale=2; ${sizetotal}/1024") $sizegeralusado);\"></div></div> </td> </tr>" >> $videomovelog
echo "<tr> <td>Videos armazenados (ultimos 7 dias)</td> <td id=\"tdxr\">${ivdexist} videos</td> <td id=\"tdxr\">$(bc <<< "scale=2; ${sizeexist}/1024/1024/1024") Gb</td> <td id=\"tdxr\">(total videos) $(bc <<< "scale=2; ${sizetotal}/1024/1024/1024") Gb</td> <td id=\"tdxr\">$(obterpercentual $sizeexist $sizetotal)</td> <td><div id=\"myProgress\"><div id=\"myBar\" style=\"width:$(obterpercentual $sizeexist $sizetotal);\"></div></div></td> </tr>" >> $videomovelog
echo "<tr> <td>Videos armazenados [weekago] (ultimos 7-14 dias)</td> <td id=\"tdxr\">${ivdmove} videos</td> <td id=\"tdxr\">$(bc <<< "scale=2; ${sizemove}/1024/1024/1024") Gb</td> <td id=\"tdxr\">(total videos) $(bc <<< "scale=2; ${sizetotal}/1024/1024/1024") Gb</td> <td id=\"tdxr\">$(obterpercentual $sizemove $sizetotal)</td> <td><div id=\"myProgress\"><div id=\"myBar\" style=\"width:$(obterpercentual $sizemove $sizetotal);\"></div></div></td> </tr>" >> $videomovelog
echo "<tr> <td style=\"color:MediumSeaGreen;\"><b>Videos recentemente adicionados (ultimas 12 horas)</b></td> <td id=\"tdxr\">${ivdnovos} videos</td> <td id=\"tdxr\">$(bc <<< "scale=2; ${sizenovos}/1024/1024/1024") Gb</td> <td id=\"tdxr\">(total videos) $(bc <<< "scale=2; ${sizetotal}/1024/1024/1024") Gb</td> <td id=\"tdxr\">$(obterpercentual $sizenovos $sizetotal)</td> <td><div id=\"myProgress\"><div id=\"myBar\" style=\"width:$(obterpercentual $sizenovos $sizetotal);\"></div></div></td> </tr>" >> $videomovelog
echo "<tr> <td style=\"color:Tomato;\"><b>Videos antigos removidos (+ de 14 dias)</b></td> <td id=\"tdxr\">${irmcount} videos</td> <td id=\"tdxr\">$(bc <<< "scale=2; ${sizerm}/1024/1024/1024") Gb</td> <td id=\"tdxr\">(total videos) $(bc <<< "scale=2; ${sizetotal}/1024/1024/1024") Gb</td> <td id=\"tdxr\">$(obterpercentual $sizerm $sizetotal)</td> <td><div id=\"myProgress\"><div id=\"myBar\" style=\"width:$(obterpercentual $sizerm $sizetotal);\"></div></div></td> </tr>" >> $videomovelog
echo "</table> <br>" >> $videomovelog

echo "<table> <caption><u><h3>Resumo do uso de particoes do Raspberry</h3></u></caption> <tr> <th>Filesystem</th> <th>Type</th> <th id=\"tdxr\">Size</th> <th id=\"tdxr\">Used</th> <th id=\"tdxr\">Avail</th> <th id=\"tdxr\">Use%</th> <th style=\"width:200px;\"></th> <th>Mounted on</th> </tr>" >> $videomovelog
df -PTh | sed '1d' | sort -n -k6 | awk '
{
    printf "\n\t<tr>";
    for (n = 1; n < 7; ++n)
       if (n == 6) {
           printf("\n\t<td id=\"tdxr\">%s</td>",$n);
           printf("\n\t<td> <div id=\"myProgress\"><div id=\"myBar\" style=\"width:%s;\"></div></div></td>",$n); }
       else if ((n > 2) && (n < 7)) 
           printf("\n\t<td id=\"tdxr\">%s</td>",$n);
       else
           printf("\n\t<td>%s</td>",$n);
    printf "\n\t<td>";
    for(;n <= NF; ++n)
       printf("%s ",$n);
    printf "</td>\n\t</tr>"
}' >> $videomovelog
echo "</table> <br>" >> $videomovelog

echo "<table> <caption><u><h3>Estatisticas das cameras IP</h3></u></caption> <tr> <th>IP Camera</th> <th>+ Antigo</th> <th>+ Recente</th> <th id=\"tdxr\" style=\"width:120px;\">Arquivos de video</th> <th id=\"tdxr\" style=\"width:120px;\">Tamanho</th> <th id=\"tdxr\" style=\"width:120px; \">Media</th> <th id=\"tdxr\" style=\"width:180px;\">Tamanho total</th> <th id=\"tdxr\" style=\"width:80px;\">Uso%</th> <th style=\"width:200px;\"></th></tr>" > $videomovetab

sizetotal="${sizeexist}"

declare -a camerainfo=( $($bindir/ipcaminfo.sh 81) )
ipcamname="${camerainfo[1]}"
ipcadd="${camerainfo[0]}"
ivdexist="`ls -l ${raspberryhd}/IPC.${ipcamname}* | grep -v ^l | wc -l`"
sizeexist="`find ${raspberryhd} -maxdepth 1 -name "IPC.${ipcamname}*" -ls | awk '{total += $7} END {print total}' 2>> $operationslog`"
oldfilerec=$(find ${raspberryhd}/IPC.${ipcamname}* -type f -printf '%T+ %p\n' | sort | head -n 1 | cut -d'.' -f 1 2>> $operationslog)
oldfiledt="$(echo $oldfilerec | cut -d'+' -f 1) $(echo $oldfilerec | cut -d'+' -f 2)"
newfilerec=$(ls -t ${raspberryhd}/IPC.${ipcamname}* | head -n1)
newfiledt=$(stat -c %y "${newfilerec}" | cut -d'.' -f1)
echo "<tr> <td>${ipcamname} ( IPv4 ${ipcadd} )</td> <td>${oldfiledt}</td> <td>${newfiledt}</td> <td id=\"tdxr\">${ivdexist} videos</td> <td id=\"tdxr\">$(bc <<< "scale=2; ${sizeexist}/1024/1024/1024") Gb</td> <td id=\"tdxr\">$(bc <<< "scale=2; ${sizeexist}/1024/${ivdexist}") Kb</td> <td id=\"tdxr\">(total videos) $(bc <<< "scale=2; ${sizetotal}/1024/1024/1024") Gb</td> <td id=\"tdxr\">$(obterpercentual $sizeexist $sizetotal)</td> <td><div id=\"myProgress\"><div id=\"myBar\" style=\"width:$(obterpercentual $sizeexist $sizetotal);\"></div></div></td> </tr>" >> $videomovetab

declare -a camerainfo=( $($bindir/ipcaminfo.sh 83) )
ipcamname="${camerainfo[1]}"
ipcadd="${camerainfo[0]}"
ivdexist="`ls -l ${raspberryhd}/IPC.${ipcamname}* | grep -v ^l | wc -l`"
sizeexist="`find ${raspberryhd} -maxdepth 1 -name "IPC.${ipcamname}*" -ls | awk '{total += $7} END {print total}' 2>> $operationslog`"
oldfilerec=$(find ${raspberryhd}/IPC.${ipcamname}* -type f -printf '%T+ %p\n' | sort | head -n 1 | cut -d'.' -f 1 2>> $operationslog)
oldfiledt="$(echo $oldfilerec | cut -d'+' -f 1) $(echo $oldfilerec | cut -d'+' -f 2)"
newfilerec=$(ls -t ${raspberryhd}/IPC.${ipcamname}* | head -n1)
newfiledt=$(stat -c %y "${newfilerec}" | cut -d'.' -f1)
echo "<tr> <td>${ipcamname} ( IPv4 ${ipcadd} )</td> <td>${oldfiledt}</td> <td>${newfiledt}</td>  <td id=\"tdxr\">${ivdexist} videos</td> <td id=\"tdxr\">$(bc <<< "scale=2; ${sizeexist}/1024/1024/1024") Gb</td> <td id=\"tdxr\">$(bc <<< "scale=2; ${sizeexist}/1024/${ivdexist}") Kb</td> <td id=\"tdxr\">(total videos) $(bc <<< "scale=2; ${sizetotal}/1024/1024/1024") Gb</td> <td id=\"tdxr\">$(obterpercentual $sizeexist $sizetotal)</td> <td><div id=\"myProgress\"><div id=\"myBar\" style=\"width:$(obterpercentual $sizeexist $sizetotal);\"></div></div></td> </tr>" >> $videomovetab

declare -a camerainfo=( $($bindir/ipcaminfo.sh 84) )
ipcamname="${camerainfo[1]}"
ipcadd="${camerainfo[0]}"
ivdexist="`ls -l ${raspberryhd}/IPC.${ipcamname}* | grep -v ^l | wc -l`"
sizeexist="`find ${raspberryhd} -maxdepth 1 -name "IPC.${ipcamname}*" -ls | awk '{total += $7} END {print total}' 2>> $operationslog`"
oldfilerec=$(find ${raspberryhd}/IPC.${ipcamname}* -type f -printf '%T+ %p\n' | sort | head -n 1 | cut -d'.' -f 1 2>> $operationslog)
oldfiledt="$(echo $oldfilerec | cut -d'+' -f 1) $(echo $oldfilerec | cut -d'+' -f 2)"
newfilerec=$(ls -t ${raspberryhd}/IPC.${ipcamname}* | head -n1)
newfiledt=$(stat -c %y "${newfilerec}" | cut -d'.' -f1)
echo "<tr> <td>${ipcamname} ( IPv4 ${ipcadd} )</td> <td>${oldfiledt}</td> <td>${newfiledt}</td> <td id=\"tdxr\">${ivdexist} videos</td> <td id=\"tdxr\">$(bc <<< "scale=2; ${sizeexist}/1024/1024/1024") Gb</td> <td id=\"tdxr\">$(bc <<< "scale=2; ${sizeexist}/1024/${ivdexist}") Kb</td> <td id=\"tdxr\">(total videos) $(bc <<< "scale=2; ${sizetotal}/1024/1024/1024") Gb</td> <td id=\"tdxr\">$(obterpercentual $sizeexist $sizetotal)</td> <td><div id=\"myProgress\"><div id=\"myBar\" style=\"width:$(obterpercentual $sizeexist $sizetotal);\"></div></div></td> </tr>" >> $videomovetab

declare -a camerainfo=( $($bindir/ipcaminfo.sh 85) )
ipcamname="${camerainfo[1]}"
ipcadd="${camerainfo[0]}"
ivdexist="`ls -l ${raspberryhd}/IPC.${ipcamname}* | grep -v ^l | wc -l`"
sizeexist="`find ${raspberryhd} -maxdepth 1 -name "IPC.${ipcamname}*" -ls | awk '{total += $7} END {print total}' 2>> $operationslog`"
oldfilerec=$(find ${raspberryhd}/IPC.${ipcamname}* -type f -printf '%T+ %p\n' | sort | head -n 1 | cut -d'.' -f 1 2>> $operationslog)
oldfiledt="$(echo $oldfilerec | cut -d'+' -f 1) $(echo $oldfilerec | cut -d'+' -f 2)"
newfilerec=$(ls -t ${raspberryhd}/IPC.${ipcamname}* | head -n1)
newfiledt=$(stat -c %y "${newfilerec}" | cut -d'.' -f1)
echo "<tr> <td>${ipcamname} ( IPv4 ${ipcadd} )</td> <td>${oldfiledt}</td> <td>${newfiledt}</td> <td id=\"tdxr\">${ivdexist} videos</td> <td id=\"tdxr\">$(bc <<< "scale=2; ${sizeexist}/1024/1024/1024") Gb</td> <td id=\"tdxr\">$(bc <<< "scale=2; ${sizeexist}/1024/${ivdexist}") Kb</td> <td id=\"tdxr\">(total videos) $(bc <<< "scale=2; ${sizetotal}/1024/1024/1024") Gb</td> <td id=\"tdxr\">$(obterpercentual $sizeexist $sizetotal)</td> <td><div id=\"myProgress\"><div id=\"myBar\" style=\"width:$(obterpercentual $sizeexist $sizetotal);\"></div></div></td> </tr>" >> $videomovetab

echo "</table><br><br>" >> $videomovetab
cat $videomovetab >> $videomovelog
echo "<p style=\"color:Blue;\"><small>Detalhes das operacoes realizadas em: '$operationslog'.</small></p>" >> $videomovelog
echo "</body> </html>" >> $videomovelog

mailx -a 'Content-Type: text/html' -s "Raspberry: relatorio do monitoramento uso do HD externo [${quando}]" darney.lampert@gmail.com < $videomovelog
rm "${videomovelog}" 2>> $operationslog > /dev/null
rm "${videomovetab}" 2>> $operationslog > /dev/null
quandodth="`date +%Y-%m-%d\ %H:%M:%S`"
echo "" >> $operationslog
echo "--[ Final ]-----------------: ${quandodth} " >> $operationslog
echo "" >> $operationslog
