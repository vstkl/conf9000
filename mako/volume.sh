volume=$(pactl get-sink-volume $(pactl get-default-sink))
volume=$(echo "$volume" | grep -E '[0-9]*%' -o | sort | uniq)

notify-send -t 1000 -c 'volume' -a 'pactl' -h int:value:$volume "Volume: ${volume}%"
