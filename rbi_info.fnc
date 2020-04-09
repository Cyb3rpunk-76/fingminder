#!/bin/bash
export info_cpu=$(uname -m)
export info_hostname=$(uname -n)
export info_so="$(uname -o) $(uname -r)"
export info_gpu_temp=$(sudo /opt/vc/bin/vcgencmd measure_temp)
export info_gpu_temp=${info_gpu_temp:5:2}${info_gpu_temp:8:1}
export info_cpu_temp=$(</sys/class/thermal/thermal_zone0/temp)
export info_cpu_temp=${info_cpu_temp:1:3}
export info_uptime=$(awk '{printf "%s Days, %02d:%02d:%02d", int($0/86400), int($0%86400/3600),int(($0%3600)/60),int($0%60) }' /proc/uptime)
#echo $info_cpu_temp
#echo $info_gpu_temp
