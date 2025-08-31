#/usr/bin/env bash
VER=6.0

if [ -n $IDF_TOOLS_PATH ]; then
	export IDF_TOOLS_PATH=/opt/esp/idf/v$VER
	export IOT_SOLUTION_PATH=/opt/esp/iot-solution
fi

alias idf='. $IDF_TOOLS_PATH/export.sh'
