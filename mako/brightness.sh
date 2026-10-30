b_cur=$(brightnessctl g)
b_max=$(brightnessctl m)
brightness=$((b_cur * 100 / b_max))
# echo $brightness
notify-send -t 1000 -h string:x-canonical-private-synchronous:brightness -a 'brightness' -h int:value:$brightness "Brightness: ${brightness}%"
