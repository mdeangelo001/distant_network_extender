#! /bin/bash

service hostapd stop
service dnsmasq stop

# TODO: remove wlan0 and eth0 from managed devices in Network Manager

ifconfig wlan0 0.0.0.0/0 up
iwconfig wlan0 mode managed channel 1
ifconfig eth0  0.0.0.0/0 up
brctl delbr br0
brctl addbr br0
brctl addif br0 eth0
iw dev wlan0 set 4addr on
brctl addif br0 wlan0
ifconfig br0 172.23.13.1/24 up

service hostapd start
service dnsmasq start
echo '1' > /proc/sys/net/ipv4/ip_forward
iptables --table nat --append POSTROUTING --out-interface wlan1 -j MASQUERADE -s 172.23.13.0/24
iptables --append FORWARD -s 172.23.13.0/24 -j ACCEPT
iptables --append FORWARD -d 172.23.13.0/24 -j ACCEPT -m conntrack --ctstate ESTABLISHED,RELATED -i wlan1
