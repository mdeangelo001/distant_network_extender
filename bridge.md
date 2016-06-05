```
sudo ifconfig eth0 0.0.0.0 up
sudo ifconfig wlan0 0.0.0.0 up
sudo brctl addbr br0
sudo brctl addif br0 eth0
sudo iw dev wlan0 set 4addr on
sudo brctl addif br0 wlan0
brctl show
```
