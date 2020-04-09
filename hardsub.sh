#!/bin/bash

# --------------------------------------------------
# HARDSUB = Hard coded Subtitle
# Burns directly on movie frame the text subtitle,
# and removes ( text ) after complete.
#
# Darney Lampert, 19.01.2018
# --------------------------------------------------

# Funcao que cria diretorio, caso nao exista
function mkdir_ifnot {
  if ! [ -e $1 ] 
  then
    mkdir $1
  fi
  return 0
}

# Roda em cima de todos os videos do mesmo tipo no diretorio
function run_all_type {
  count=`ls -1 *.$1 2>/dev/null | wc -l`
  if [ $count != 0 ]
  then 
    for filexx in *.$1 ; do
      echo "$filexx"
      mk_hardsubtitle_ffmpeg $filexx ; done
  fi
  return 0
}

# Gera log
function loginfo {
  printf "%s " `date +%Y-%m-%d_%H-%M-%S`" - "$1 >> .hardsub/hardsub.log
  printf "\n" >> .hardsub/hardsub.log
  return 0
}

# Regera o filme com a legenda usando FFMPEG
function mk_hardsubtitle_ffmpeg {
  defaultEXT=.mp4
  VIDEO_IN_FILE=$1
  VIDEO_WORK_FILE=hardsub.work.$1
  inEXT=.${VIDEO_IN_FILE##*.}
  VIDEO_IN_SRT=$(basename $VIDEO_IN_FILE $inEXT).srt
  # Verifica se o arquivo de trabalho existe, se sim, apaga
  if [ -f "$VIDEO_WORK_FILE" ]; then
    rm "$VIDEO_WORK_FILE" 
  fi
  # Verifica se o filme existe
  if [ ! -f "$VIDEO_IN_FILE" ]; then
    echo input file \"$VIDEO_IN_FILE\" does not exist [SKIPPED]
    return 1
  fi
  if [ ! -f "$VIDEO_IN_SRT" ]; then
    loginfo input SRT subtitle file \"$VIDEO_IN_SRT\" does not exist [SKIPPED]
    return 1
  fi
  echo "Hard coding \"$VIDEO_IN_FILE\" with SRT Subtitle ... "
  CMD="ffmpeg -i \"$VIDEO_IN_FILE\" -vf subtitles=\"$VIDEO_IN_SRT\" -c:a copy \"$VIDEO_WORK_FILE\""
  echo $CMD
  eval $CMD 2> /dev/null > /dev/null
  if [ $? != 0 ]; then
    rm \"$VIDEO_WORK_FILE\"
    loginfo "Video \"$VIDEO_IN_FILE\" with SRT Subtitle get [ERROR] :-( " 
    return 1
  else
    mv $VIDEO_IN_FILE .hardsub/$VIDEO_IN_FILE
    if [ $? != 0 ]; then
      return 1
    fi  
    mv $VIDEO_IN_SRT .hardsub/$VIDEO_IN_SRT
    if [ $? != 0 ]; then
      return 1
    fi  
    mv $VIDEO_WORK_FILE $VIDEO_IN_FILE
    if [ $? != 0 ]; then
      return 1
    fi  
    loginfo "Hard coded \"$VIDEO_IN_FILE\" with SRT Subtitle [DONE] :-) "
  fi
  return 0
}

# corpo do shell

mkdir_ifnot .hardsub
if ! [ -e .hardsub ] 
then
  echo "Cant write on actual directory ( \".\" ) [ERROR] "
  exit 1
fi

if [ -z "$1" ]; then
  echo usage: $0 movie.[avi/mp4/mkv]
  echo    or: $0 -all
  echo 
  echo -all = will process all movie files on current directory
  exit 1
fi

if [ "$1" == "-all" ]; then
  run_all_type avi
  run_all_type mkv
  run_all_type mp4
else
  mk_hardsubtitle_ffmpeg $1
fi

exit 0
