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

##Influx:
#Counter,idx=113,name=stromzaehler-aus-2.8.0
#Counter,idx=114,name=stromzaehler-ein-1.8.0
#Counter,idx=115,name=stromzaehler
INFLUX_URL=https://eu-central-1-1.aws.cloud2.influxdata.com
INFLUX_TOKEN=rnBcm2cHFZGEvax6KlxTXSeoyF3gGmm5KpyeRx1MzlGB2gW7tz_PTWQo0exthhEOkCK2lU6QxxFR92elg7GkjQ==
INFLUX_ORG=99702231a4477a51
INFLUX_BUCKET=oranienbaum-energy

function influx2_write_line {
  local line="$1"
  #Counter,idx=114,name=stromzaehler-ein-1.8.0  value=$METER_180
  curl -sS -X POST\
    -H "Authorization: Token $INFLUX_TOKEN"\
    -H "Content-Type: text/plain; charset=utf-8"\
    -H "Accept: application/json"\
    -d "$line"\
    "$INFLUX_URL/api/v2/write?bucket=$INFLUX_BUCKET"
}

if [[ $METER_180 =~ ^[0-9]+$ ]]
then
  echo "Meter 1.8.0 (from plant):    " $METER_180 "kWh" 1>&2
  influx2_write_line "Counter,idx=114,name=stromzaehler-ein-1.8.0  value=$METER_180"
  #curl -sS -X POST -d "Counter,idx=114,name=stromzaehler-ein-1.8.0  value=$METER_180" "192.168.178.101:8086/write?db=domoticz"
#  curl -sS "192.168.178.101:8080/json.htm?type=command&param=udevice&idx=114&svalue=$METER_180"
fi

if [[ $METER_280 =~ ^[0-9]+$ ]]
then
  echo "Meter 2.8.0 (to plant):      " $METER_280 "kWh" 1>&2
  influx2_write_line "Counter,idx=113,name=stromzaehler-ein-2.8.0  value=$METER_280"
  #curl -sS -X POST -d "Counter,idx=113,name=stromzaehler-ein-2.8.0  value=$METER_280" "192.168.178.101:8086/write?db=domoticz"
#  curl -sS "192.168.178.101:8080/json.htm?type=command&param=udevice&idx=113&svalue=$METER_280"
fi

if [[ $METER_280 =~ ^[0-9]+$ ]] && [[ $METER_180 =~ ^[0-9]+$ ]]
then
  echo "in - out = $(( METER_280 - METER_180 ))" 1>&2
  influx2_write_line "Counter,idx=115,name=stromzaehler  value=$(( METER_280 - METER_180 ))"
  #curl -sS -X POST -d "Counter,idx=115,name=stromzaehler  value=$(( METER_280 - METER_180 ))" "192.168.178.101:8086/write?db=domoticz"
#  curl -sS "192.168.178.101:8080/json.htm?type=command&param=udevice&idx=115&svalue=$(( METER_280 - METER_180 ))"
fi

