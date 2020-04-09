#!/bin/bash

round() {
    printf "%.$2f" $(echo "scale=2;$1" | bc | sed 's/[.]/,/')
}

math() {
    echo "$*" | bc -l
}

if [ $# -lt 1 ]
then
   echo "Syntaxe : "$0" [IP or last IP Number]"
else
  case "$1" in
    80|10.10.10.80) echo "Fundos.Movel"
    ;;
    81|10.10.10.81) echo "Fundos.Piscina"
    ;;
    82|10.10.10.82) echo "Sala.da.TV"
    ;;
    83|10.10.10.83) echo "Frente.Garagem"
    ;;
    84|10.10.10.84) echo "Frente.Porta.da.Casa"
    ;;
    85|10.10.10.85) echo "Fundos.Sacadao"
    ;;
    *)  echo "Camera.desconhecida..."
    ;;
  esac
fi
