#!/bin/bash
# read and evaluate SML output received from EMH eHZ
# http://wiki.volkszaehler.org/hardware/channels/meters/power/edl-ehz/emh-ehz-h1
# input formated as one line  
# ---------------------------------------------------------------------------
# FU modified 20130712 for EMH ED300L
# ---------------------------------------------------------------------------
 
INPUT_DEV="/dev/ttyUSB0"

#set $INPUT_DEV to 9600 8N1
stty -F $INPUT_DEV 1:0:8bd:0:3:1c:7f:15:4:5:1:0:11:13:1a:0:12:f:17:16:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0

SML_START_SEQUENCE="1B1B1B1B0101010176"
MESSAGE_LENGTH=368

ml=$((MESSAGE_LENGTH+2))
for counter in 1 2 3
do
	#xxd -ps -u -l 400 $INPUT_DEV | tr -d '\n' | perl -pe "s@^.*?($SML_START_SEQUENCE.*?)$SML_START_SEQUENCE.*\$@\1@" | wc -c
	METER_OUTPUT=`xxd -ps -u -l $ml $INPUT_DEV | tr -d '\n' | perl -pe "s@^.*?$SML_START_SEQUENCE@$SML_START_SEQUENCE@"`
        output_length=$(echo ${METER_OUTPUT} | wc -c)

        if [ "$output_length" -le 368 ] #read bytes at position 358 + 10
        then
                echo "something went wrong trying again..." 1>&2
		echo "$METER_OUTPUT" 1>&2
	        echo $output_length 1>&2
		ml=$((MESSAGE_LENGTH*2))
		sleep 5
                #exit 1 
	else
		break
        fi
done

#let METER_180=0x${METER_OUTPUT:390:10}
let METER_180=0x${METER_OUTPUT:310:10}

#let METER_280=0x${METER_OUTPUT:347:10}
let METER_280=0x${METER_OUTPUT:358:10}
echo -n "Meter 1.8.0 (from plant):     " 1>&2
echo -n "$METER_180 "
echo    "kWh" 1>&2
echo -n "Meter 2.8.0 (to plant):       " 1>&2
echo -n $METER_280
echo    " kWh" 1>&2

#let METER_180=0x${METER_OUTPUT:599:8}
#VALUE=$(echo "scale=2; $METER_180 / 10" |bc)
#echo "Total effective power (+/-): " $VALUE "W"
