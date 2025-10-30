b_cur=$(brightnessctl g)
b_max=$(brightnessctl m)
brightness=$((b_cur * 100 / b_max))
# echo $brightness
notify-send -t 1000 -a 'brightness' -h int:value:$brightness "Brightness: ${brightness}%"
