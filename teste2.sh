#!/bin/bash

lst_id="${1}"
cam_id="${2}"

if [ ! -z "$cam_id" ]; then
    if [ "$cam_id" == "21" ]; then        
        cam_id="83"
    fi    
    if [ ! "$cam_id" == "${lst_id}" ]; then 
        if [ ! "$cam_id" == "17" ]; then 
            echo "--DIFERENTE: ${lst_id} ~ ${cam_id}"
        fi    
    else
        echo "--GRAVAR: ${lst_id}"
    fi
else
    echo "--VAZIO"
fi    
