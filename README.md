# distant_network_extender
Setup Notes and files to connect Pine64 computer to a distant WiFi and create a local wifi and wired network.

## Overview
Sometimes I am in a location where there is a distant WiFi hotspot, but I can't use it. For example at some hotels there is lobby WiFi that does not reach the rooms. My local cable company provides public WiFi in many parks, beaches, and other public places but the signal may not be strong enough to work reliably near me.

I'm using a small single board ARM based computer from Pine64 http://pine64.com/ running Ubuntu Linux. The Pine64 is similar to the popular Raspberry Pi computers. I plan to use a directional high gain antenna to connect to a distant WiFi hotspot. Then I will share that network connection by configuring the WiFi chip on the Pine64 as an Access Point - possible bridging it with the on-board wired Ethernet - and configuring NAT and iptables to forward the local traffic to the distant WiFi.

## Parts

These are the parts that I am using:

1. Pine64 computer - 2GB RAM version - with on board WiFi/BlueTooth. Approx $40.
2. Enclosure - I used one I found on eBay similar to this one - http://www.ebay.com/itm/Carcasa-Caja-acrilica-para-PINE-A64-64plus-Battery-Holder-Acryl-Gehause-DIY-CASE-/361576814059 - $20. (In the future that link may be dead, but the seller is http://www.ebay.com/usr/guitarreriacom)
3. USB wifi device with a standard jack for an external antenna. I used this one TP-LINK TL-WN722N Wireless N150 High Gain USB Adapter since it is known to work well with Linux - http://smile.amazon.com/TP-LINK-TL-WN722N-Wireless-Adapter-External/dp/B002SZEOLG - $14
4. Directional High Gain Antenna - I purchased a Cantenna from http://www.ebay.com/usr/hughpep. They are easy to build, but by the time I got all the parts together it was easier just to buy one of these. $20
5. I already had a microsd card, keyboard and mouse, power supply, etc.
 
## Steps

These steps are not currently tested. They are my expected path.

### one time setup

1. Flash ubuntu on microsd card and configure Pine64.
2. Install/update packages. Using Mate Desktop currently. Package list to be added later.
3. Add udev rule so that External wireless card gets a reasonable device name like wlan1 (assume internal wireless gets wlan0).
4. Configure iptables and forwarding enabled.
5. Install hostapd and dnsmasq

### to use

1. Put wlan0 in AP mode with WPA2 PSK.
2. Release ip addresses from wlan0 and eth0.
3. Bridge wlan0 and eth0 as br0.
4. Bring up br0 and assign ip address.
5. Start dnsmasq providing DHCP and DNS to br0.
6. Set up ip tables to provide NAT forwarding to wlan1.
 
### Notes

https://help.ubuntu.com/community/WifiDocs/WirelessAccessPoint
https://www.linux.com/learn/create-secure-linux-based-wireless-access-point
https://wiki.debian.org/HowTo/dnsmasq
https://www.howtoforge.com/nat_iptables
http://rlworkman.net/howtos/iptables/iptables-tutorial.html#NATINTRO
