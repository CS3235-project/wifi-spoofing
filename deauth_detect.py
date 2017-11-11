#!/usr/bin/env python

""" execute with root permission
let wlan1 be the interface used for monitoring. Then either
1. Use airmon-ng wlan1 start
    to set up interface named mon0
2. Do manually:
    ifconfig wlan1 down
    iwconfig wlan1 mode monitor
    iwconfig wlan1 channel (set to whichever channel the AP is in)
    ifconfig wlan1 up

Make sure that the channel in which your AP is active and the channel your monitoring interface
is in are the same.
"""

import sys
import socket
import time 
import string
from scapy.all import *

# global variables such that they are accessible from the event handler
target_mac = None # must be lowercase
target_essid = None
deauth_count = 0
last_time_deauth_received = 0
threshold = 0

def sniff_req(packet):
    """ event handler for scapy's sniff method
        the argument is the packet received
    """
    ## DEBUG-MODE
    # if packet.haslayer(Dot11):
    #     print packet.sprintf("packet from AP [%Dot11.addr2%] to Client [%Dot11.addr1%]")

    # look for a deauth packet
    if packet.haslayer(Dot11Deauth):
        global deauth_count, last_time_deauth_received
        if True: # just to avoid changing indentation
            current_time = time.time()
            if current_time - last_time_deauth_received > 60:
                last_time_deauth_received = current_time
                deauth_count = 0
            deauth_count += 1
            print packet.sprintf("Deauth from AP [%Dot11.addr2%] to Client [%Dot11.addr1%], \
            Reason [%Dot11Deauth.reason%]")
            print 'count/min = %d' % (deauth_count)

def info(fm):
    if fm.haslayer(Dot11):
        if ((fm.type == 0) & (fm.subtype==8)):
            captured_essid = str(fm.info).strip()
            captured_essid = string.lower(captured_essid)
            # print captured_essid #uncomment this line to check if scanning properly
            global target_essid
            if captured_essid == target_essid:
                global target_mac
                target_mac = fm.addr2

def is_mac_found(p):
    """ function that is supposed to be passed to sniff() to terminate sniffing
    """
    global target_mac
    return target_mac != None

def find_mac_from_essid(interface):
    """ converts ESSID to MAC address. Timeout is set to 4
    """
    sniff(iface=interface,prn=info, timeout=4)

def main():
    """ main function
    """
    if len(sys.argv) < 4:
        print 'Wrong command arguments'
        print '1. specify your interface used for monitoring'
        print '2. specify the network to monitor'
        print '3. specify the deauth frame count limit per min'
        print 'for example:\n ' + sys.argv[0] + ' mon0 myWifi 40'
        sys.exit()
    
    global target_mac, threshold, last_time_deauth_received, target_essid

    interface = sys.argv[1]
    target_essid = sys.argv[2]
    threshold = sys.argv[3]

    print 'scanning for the MAC address of %s' % (target_essid)
    find_mac_from_essid(interface=interface)
    if  target_mac is None:
        print 'corresponding mac address was not found.'
        print 'is the network up?'
        sys.exit()

    target_mac = string.lower(target_mac)

    last_time_deauth_received = time.time()
    # Berkeley Packet Filter format
    filter_statement = "ether src " + target_mac

    print 'now monitoring ESSID(%s) with BSSID(%s) on interface %s' % (target_essid, target_mac, interface)
    sniff(filter=filter_statement, iface=interface, prn=sniff_req)
    # sniff(iface=interface, prn=sniff_req) # uncomment this line to test that the filter is working

if __name__ == '__main__':
    main()
