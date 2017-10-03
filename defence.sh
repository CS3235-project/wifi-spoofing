#!/bin/bash

#basic version of a defence program against hotspot spoofing
#given some preferred essid and MAC, if another MAC with the same SSID exists
#a notification warns the user

MAC="58:2A:F7:9E:45:5A"
essid="HUAWEI"
while true; do
	count=0
	array=( $(sudo iwlist wlp4s0 scan | grep 'Address\|ESSID:' | grep -B 1 "\"${essid}\"") )
	for i in "${array[@]}"
	do
		if [ $(($count%7)) -eq 4 ]
		then
			#echo "${i}"
			if [ "$MAC" != "$i" ]
				then
				notify-send "Warning, "${essid}" wifi may be compromised"
				echo "Warning, unexpeced MAC : ${i}"
			fi
		fi
		((++count))
	done
	sleep 30s
done
