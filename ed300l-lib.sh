#!/bin/bash
# read and evaluate SML output received from EMH eHZ
# http://wiki.volkszaehler.org/hardware/channels/meters/power/edl-ehz/emh-ehz-h1
# input formated as one line  
# ---------------------------------------------------------------------------
# FU modified 20130712 for EMH ED300L
# ---------------------------------------------------------------------------
 
function read_180_280() {
  local INPUT_DEV SML_START_SEQUENCE MESSAGE_LENGTH ml success METER_OUTPUT counter
  INPUT_DEV="${1-/dev/ttyUSB0}"

  #set $INPUT_DEV to 9600 8N1
  stty -F $INPUT_DEV 1:0:8bd:0:3:1c:7f:15:4:5:1:0:11:13:1a:0:12:f:17:16:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0

  SML_START_SEQUENCE="1B1B1B1B0101010176"
  MESSAGE_LENGTH=368

  ml=$((MESSAGE_LENGTH))
  success=0
  for counter in 1 2 3
  do
    METER_OUTPUT=$(xxd -ps -u -l $ml $INPUT_DEV | tr -d '\n')
    METER_OUTPUT=$SML_START_SEQUENCE${METER_OUTPUT#*$SML_START_SEQUENCE}
    output_length=$(echo -n ${METER_OUTPUT} | wc -c)

    if [ "$output_length" -ge $((MESSAGE_LENGTH*2)) ]
    then
      success=1
      break
    fi
    echo "something went wrong trying again..." 1>&2
    echo "$METER_OUTPUT" 1>&2
    echo "length $output_length < $((MESSAGE_LENGTH*2))" 1>&2
    if [ $counter = 1 ]
    then
      ml=$((MESSAGE_LENGTH+2))
    elif [ $counter = 2 ]
    then
      ml=$((MESSAGE_LENGTH*2))
    fi
    sleep 5
  done
  if [ $success = 0 ]
  then
    return 1
  fi

  let METER_180=0x${METER_OUTPUT:310:10}
  let METER_280=0x${METER_OUTPUT:358:10}
  if [ $METER_180 -eq $METER_280 ]
  then
    echo $METER_OUTPUT 1>&2
    return 1
  fi

  #example wrong values:
  #558368955986
  #352243286016
  if [ $METER_180 -ge 100000000000 ] || [ $METER_280 -ge 100000000000 ]
  then
    echo $METER_OUTPUT 1>&2
    return 1
  fi
  echo $METER_180 $METER_280
}

function read_180_280_hr() {
  ab=$(read_180_280)
  METER_180=${ab% *}
  METER_280=${ab#* }
  echo "Meter 1.8.0 (from plant): $(printf %6d $METER_180) kWh"
  echo "Meter 2.8.0 (to plant):   $(printf %6d $METER_280) kWh"
}
