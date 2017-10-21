#!/bin/bash

#basic version of a defence program against hotspot spoofing
#given some preferred essid and MAC, if another MAC with the same SSID exists
#a notification warns the user

while true; do
	mapfile -t myArray < authorised.list
	index=1
	for j in `seq 0 $((${myArray[0]}-1))`; do
		echo "j is $j"
		count=0
		SSID=${myArray[index]}
		((++index))
		nbAuthorisedMacs=${myArray[index]}
		echo "Nb authorised macs is $nbAuthorisedMacs"
		((++index))
		echo "SSID is $SSID"
		array=( $(sudo iwlist wlp4s0 scan | grep 'Address\|ESSID:' | grep -B 1 "\"${SSID}\"") )
		for i in "${array[@]}"
		do
			#echo "$i"
			if [ $(($count%7)) -eq 4 ]
			then
				#echo "${i}"
				problem="YES"
				for k in `seq $index $(($index+$nbAuthorisedMacs-1))`; do
					
					if [ ${myArray[k]} == "$i" ]
						then
						problem="NO"
						fi
				done
				if [ "$problem" != "NO" ]
					then
						if [ ${i} != "ESSID:"$SSID"" ]
							then
							notify-send "Warning, wifi may be compromised"
							echo "Warning, unexpeced MAC : ${i}"
						fi				
				fi
			fi	
			((++count))
		done
		index=$(($index+$nbAuthorisedMacs))
	done
	sleep 30s
done
