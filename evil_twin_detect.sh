#!/bin/bash

#basic version of a defence program against hotspot spoofing
#given some preferred essid and MAC, if another MAC with the same SSID exists
#a notification warns the user

echo "Enter scanning interface"
read interface
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
		array=( $(iwlist ${interface} scan | grep Address ) )
		connectedMAC=${array[4]}
		nbAuthorisedMacs=${myArray[index]}
		((++index))
		if [ "$SSID" == "$connectedSSID" ]
		then
			array=( $(sudo iwlist ${interface} scan | grep 'Address\|ESSID:' | grep -B 1 "\"${SSID}\"") )
			sameMac=0
			for i in "${array[@]}"
			do
				if [ $((count%7)) -eq 4 ]
				then
					#echo "${i}"
					#echo "${connectedMAC}"
					if [ "${connectedMAC}" == "$i" ]
					then
						((++sameMac))
					fi
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
			if [ "$sameMac" != "1" ]
			then
				notify-send "Warning, wifi ${SSID} may be compromised"
				echo "Warning, there are ${sameMac} AP with identical MAC"				
			fi
		fi
		index=$((index+nbAuthorisedMacs))
	done
done
