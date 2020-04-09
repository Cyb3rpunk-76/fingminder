#!/bin/bash
iSamsungTV E $1 -SMS "" "" "" "" "" "" $2
sleep 0.3
iSamsungTV E $1 -KEY KEY_ENTER
sleep 3
iSamsungTV E $1 -KEY KEY_ENTER