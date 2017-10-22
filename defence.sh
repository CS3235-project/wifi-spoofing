#!/bin/bash

#basic version of a defence program against hotspot spoofing
#given some preferred essid and MAC, if another MAC with the same SSID exists
#a notification warns the user

mapfile -t myArray < authorised.list
while true
do
	index=1
	for j in $(seq 0 $((myArray[0]-1)))
	do
		count=0
		SSID=${myArray[index]}
		((++index))
		connectedSSID=$(iwgetid -r)	
		nbAuthorisedMacs=${myArray[index]}
		((++index))
		if [ "$SSID" == "$connectedSSID" ]
		then
			array=( $(sudo iwlist wlp4s0 scan | grep 'Address\|ESSID:' | grep -B 1 "\"${SSID}\"") )
			for i in "${array[@]}"
			do
				if [ $((count%7)) -eq 4 ]
				then
					#echo "${i}"
					problem="YES"
					for k in $(seq $index $((index+nbAuthorisedMacs-1)))
				        do
						if [ "${myArray[k]}" == "$i" ]
						then
							problem="NO"
						fi
					done
					if [ "$problem" != "NO" ] && [ "${i}" != "ESSID:\"$SSID\"" ]
					then
						notify-send "Warning, wifi ${SSID} may be compromised"
						echo "Warning, unexpeced MAC : ${i}"				
					fi
				fi	
				((++count))
			done
		fi
		index=$((index+nbAuthorisedMacs))
	done
	sleep 30s
done
