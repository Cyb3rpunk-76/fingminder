#!/bin/bash
# ---------------------------------------------------------------------
# bin.fnc = common bash shell functions
#
# Darney Lampert, 2018-02-16
# ---------------------------------------------------------------------

function trim {
  echo "$(echo -e "${1}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  return 0
}

function loginfo {
  printf "%s " `date +%Y-%m-%d_%H-%M-%S`" - "$1 >> $2.log
  printf "\n"                                   >> $2.log
  return 0
}

function mkdir_ifnote {
  if ! [[ -z "$1" ]]
  then
    if ! [[ -e $1 ]]
    then
      mkdir $1
      if ! [[ -z "$2" ]]
      then
        chmod $2 $1
      fi
    fi
  fi
  return 0
}

function rmfile_ifexist {
  if ! [[ -z "$1" ]]
  then
    if [[ -e $1 ]]
    then
      rm -f $1 2> /dev/null > /dev/null
    fi
  fi
  return 0
}
