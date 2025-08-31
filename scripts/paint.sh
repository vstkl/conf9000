#!/usr/bin/env bash

COLOR_SCHEME_PATH=$HOME/.config/color.scheme
COLOR=$(cat $COLOR_SCHEME_PATH)
ENV_NAME="BASE16_THEME"
function paint() {
	TARGET=$1

	# echo "setting from $COLOR to $TARGET theme"
	echo $TARGET >$COLOR_SCHEME_PATH
	export $ENV_NAME=$COLOR

	# echo "running "
	# echo "tinty apply $COLOR"
	tinty apply $COLOR
}
paint $COLOR
