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

SS=1B1B1B1B0101010176
ES=1B1B1B1B

HERS=8181C78203FF #Hersteller
Z009=0100000009FF #Geraetenummer
Z180=0100010800FF #Zaehlwerk: verbrauchte (pos.) Wirkenergie #10+5 bytes
Z280=0100020800FF #Zaehlwerk: erzeugte    (neg.) Wirkenergie
Z181=0100010801FF #Zaehlwerk: pos. Wirkenergie Tarif 1
Z281=0100020801FF #Zaehlwerk: neg. Wirkenergie Tarif 1
Z182=0100010802FF #Zaehlwerk: pos. Wirkenergie Tarif 2
Z182=0100020802FF #Zaehlwerk: pos. Wirkenergie Tarif 2

N=$((27*2)) #bufsize

function bytes_to_kwh() {
  local bytes="$1"
  local num=0x${bytes:20:10}
  echo $bytes
  echo $((num))
}

function first_block() {
  local start_index
  local end_index
  local s
  local b1
  local b2

  read b1
  while read b2
  do
    s=$b1$b2

    if [ -z "$start_index" ]
    then
      start_index=$(echo -n $s | grep -ob $SS | awk -F: '{ print $1;}')
                                             
      if [ "$start_index" ]
      then
        s=${s:$((start_index+18))}
        : echo -n $s
      fi
    fi

    if [ "$start_index" ]
    then
      Z180_keyval=$(echo -n $s | grep -o "7707$Z180..............................01")
      if [ "$Z180_keyval" ]
      then
        bytes=${Z180_keyval:16}
        echo "1.8.0 incoming: $(bytes_to_kwh $bytes)"
      fi

      Z280_keyval=$(echo -n $s | grep -o "7707$Z280..............................01")
      if [ "$Z280_keyval" ]
      then
        bytes="${Z280_keyval:16}"
        echo "2.8.0 outgoing: $(bytes_to_kwh $bytes)"
      fi

      end_index=$(echo -n $s | grep -ob $ES | awk -F: '{ print $1;}')
      if [ -z "$end_index" ]
      then
        : echo -n "$b2"
      else
        : #echo "${s:$N:$((end_index-N+8))}"
        : echo "end_index:$end_index"
        #echo "$(($end_index+4))"
        #break
      fi
    fi

    b1=$b2
  done 
}

xxd -u -p -c $((N/2)) $INPUT_DEV | first_block
