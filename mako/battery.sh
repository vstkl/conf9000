#!/bin/bash
BAT_TRESHOLD=5
TIME=120
while true; do
	bat_lvl=$(cat /sys/class/power_supply/BAT0/capacity)
	if [ "$bat_lvl" -le "$BAT_TRESHOLD" ]; then
		notify-send --category bat "Battery Low - : ${bat_lvl}%"
		#echo "triggering batlow"
		#timedatectl
		sleep $(($TIME * 100))
	else
		#echo "not triggering"
		#timedatectl
		sleep $TIME
	fi
done
