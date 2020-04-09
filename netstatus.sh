#!/bin/bash

declare -a hostslist=( 
      "SA!www.globo.com" 
      "SA!www.google.com"
      "SA!www.gtctelecom.com.br"
      "NA!www.github.com"
      "NA!www.sun.com"
      "NA!www.gamespot.com"
      "EU!www.airfrance.fr"
      "EU!handbrake.fr"
      "EU!www.eurolines.de"
      "AF!www.bet.co.za"
      "AF!www.kia.co.za"
      "AF!www.cdf.gov.eg"
      "AS!www.kis.or.kr"
      "AS!www.khl.ru"
      "AS!en.rti.org.tw" )

RED='\033[1;31m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELOOW='\033[1;33m'
NC='\033[0m' # Sem cor

ALERTDELAYLIMIT=800
ALERTMODE="N"
SAIR="N"
OUTPUTMODE="C"
DETAILMODE="Y"

ObterDescRegiao () {
  case "$1" in
	"SA") 
	  echo "South America"
	  ;;
	"NA")  
	  echo "North America"
	  ;;
	"EU")  
	  echo "Europe"
	  ;;
	"AF")  
	  echo "Africa"
	  ;;
	"AS")  
	  echo "Asia"
	  ;;
	*)  
	  echo "World"
	  ;;
  esac
}

AjudaSyntaxe () {
  echo ""
  echo " Syntaxe: $0 [options]"
  echo ""
  echo " OPTIONS:"
  echo "  -h,--help,-?:      Show this message"
  echo "  -a,--alert:        Set alert mode: show only hosts with problems (> ${ALERTDELAYLIMIT} ms)"
  echo "  -ox,--outputxml:   Set output to XML mode"
  echo "  -oc,--outputcsv:   Set output to CSV mode"
  echo "  -ot,--outputtele:  Set output to Telegram mode"
  echo ""
}

EfetuaEcho() {
  doecho="Y"
  etping="$4"
  prfx="$4"
  if [ ! "$prfx" = "OFF" ]; then
	prfx="ON"
	if [ ! "$ALERTMODE" = "N" ]; then
      if (( $(echo "$etping < $ALERTDELAYLIMIT" |bc -l) )); then	
	    doecho="N"
	  fi
	fi  
  fi
  corusada="$3"
  ehost="$1"
  earea="$2"
  case $OUTPUTMODE in
		C)
		  ehost="$(printf '%-024s\n' "$ehost")"
		  earea="$(ObterDescRegiao "$earea")"
		  earea="$(printf '%-15s\n' "$earea")"
 		  if [ "$etping" = "OFF" ]; then
		    etping=""
		  else
		    etping="$(printf ' %8s\n' "$etping")"
		  fi
 		  if [ "$doecho" = "Y" ]; then
		    echo -e "$earea - $ehost ${corusada}[${prfx}LINE]${NC}$etping"
		  fi
		  ;;
		S)
		  if [ "$doecho" = "Y" ]; then
		    echo -e "$earea;$ehost;$prfx;$etping"
		  fi	
		  ;;
		X)
		  if [ "$doecho" = "Y" ]; then
		    earea2="$(ObterDescRegiao "$earea")"
			printf "  <SITE>\n     <IDCONTINENT>%s</IDCONTINENT>\n     <CONTINENT>%s</CONTINENT>\n     <URL>%s</URL>\n     <STATUS>%s</STATUS>\n     <LATENCY>%s</LATENCY>\n  </SITE>\n" "$earea" "$earea2" "$ehost" "$prfx" "$etping"
		  fi	
		  ;;
		T)
		  case "$earea" in
		    "SA"|"NA") 
			  earea=":earth_americas:${earea}"
			  ;;
			"EU"|"AF")  
			  earea=":earth_africa:${earea}"
			  ;;
			"AS")  
			  earea=":earth_asia:${earea}"
			  ;;
			*)  
			  earea=":earth_americas:${earea}"
			  ;;
		  esac
		  if [ "$etping" = "OFF" ]; then
		    etping="offline"
		  else
		    etping="$etping ms"
		  fi	
 		  if [ "$doecho" = "Y" ]; then
            echo -e "${corusada}${earea}  ${ehost} ( $etping )"
		  fi
		  ;;
  esac
}
	  
EfetuaPing () {
  host=$(echo $1 | cut -d! -f2)
  area=$(echo $1 | cut -d! -f1)
  tping=$(ping -c 4 $host | tail -1| awk '{print $4}' | cut -d '/' -f 2)
  if [ ! "$tping" = "" ]; then
	if (( $(echo "$tping > 450" |bc -l) )); then
	  ONL=$RED
	else
	  if (( $(echo "$tping > 250" |bc -l) )); then
		ONL=$YELOOW
	  else
		ONL=$GREEN
	  fi
	fi
  else
	ONL=$BLUE
	tping="OFF"
  fi
  EfetuaEcho "$host" "$area" "$ONL" "$tping"
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
	key="$1"
	case $key in
		-a|--alertmode)
		ALERTMODE="Y"
		shift
		;;
		-ox|--outputxml)
		OUTPUTMODE="X"
		shift
		;;
		-oc|--outputcsv)
		OUTPUTMODE="S"
		shift
		;;
		-ot|--outputtele)
		OUTPUTMODE="T"
		shift
		;;
		#-h|--help|-?)
		*)
		SAIR="Y"
		shift
		;;
	esac
done
set -- "${POSITIONAL[@]}"

if [ "$SAIR" = "N" ]; then
	case $OUTPUTMODE in
	    T)
	    RED=":o2:"
	    BLUE=":arrow_down:"
	    GREEN=":eight_spoked_asterisk:"
	    YELOOW=":eight_pointed_black_star:"
	    NC=""
		;;
		C)
        echo ""
		;;
		X)
		echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
		echo "<WORLD>"
		;;
	esac
    pids=()
	for ho in "${hostslist[@]}"; do
	   EfetuaPing "$ho" &
	   pids+=($!)
	done
	wait "${pids[@]}"
	case $OUTPUTMODE in
		C)
        echo ""
		;;
		X)
		echo "</WORLD>"
		;;
	esac
else	
	AjudaSyntaxe
fi
