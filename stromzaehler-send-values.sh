#!/bin/bash
date +"%Y-%m-%d %H:%M:%S"

source $HOME/ed300l-lib.sh

a_b=$(read_180_280)
if [ $? -ne 0 ]
then
  exit 1
fi
METER_180=${a_b% *}
METER_280=${a_b#* }
if [[ $METER_180 =~ ^[0-9]+$ ]]
then
  echo "Meter 1.8.0 (from plant):    " $METER_180 "kWh" 1>&2
  curl -sS "192.168.178.101:8080/json.htm?type=command&param=udevice&idx=114&svalue=$METER_180"
fi

if [[ $METER_280 =~ ^[0-9]+$ ]]
then
  echo "Meter 2.8.0 (to plant):      " $METER_280 "kWh" 1>&2
  curl -sS "192.168.178.101:8080/json.htm?type=command&param=udevice&idx=113&svalue=$METER_280"
fi

if [[ $METER_280 =~ ^[0-9]+$ ]] && [[ $METER_180 =~ ^[0-9]+$ ]]
then
  echo "in - out = $(( METER_280 - METER_180 ))" 1>&2
  curl -sS "192.168.178.101:8080/json.htm?type=command&param=udevice&idx=115&svalue=$(( METER_280 - METER_180 ))"
fi

