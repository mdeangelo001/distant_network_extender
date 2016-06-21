#! /bin/bash

LOCAL_WIFI_NET_DEVICE=wlan0
LOCAL_WIRE_NET_DEVICE=eth0
LOCAL_BRIDGE_NET_DEVICE=br0
LOCAL_IP_ADDRESS=172.23.13.1/24 
LOCAL_IP_NETWORK=172.23.13.0/24 
LOCAL_WIFI_CHANNEL=1
REMOTE_WIFI_NET_DEVICE=wlan1

build_bridge() {
  brctl addbr ${LOCAL_BRIDGE_NET_DEVICE}
  ip addr flush dev ${LOCAL_WIFI_NET_DEVICE}
  iw dev ${LOCAL_WIFI_NET_DEVICE} set 4addr on
  brctl addif ${LOCAL_BRIDGE_NET_DEVICE} ${LOCAL_WIFI_NET_DEVICE}
  ip addr flush dev ${LOCAL_WIRE_NET_DEVICE}
  brctl addif ${LOCAL_BRIDGE_NET_DEVICE} ${LOCAL_WIRE_NET_DEVICE}
  ip link set ${LOCAL_BRIDGE_NET_DEVICE} up
  ip addr add ${LOCAL_IP_ADDRESS} dev ${LOCAL_BRIDGE_NET_DEVICE}
}

tear_down_bridge() {
  ip addr flush dev ${LOCAL_BRIDGE_NET_DEVICE}
  brctl delif ${LOCAL_BRIDGE_NET_DEVICE} ${LOCAL_WIFI_NET_DEVICE}
  iw dev ${LOCAL_WIFI_NET_DEVICE} set 4addr off
  brctl delif ${LOCAL_BRIDGE_NET_DEVICE} ${LOCAL_WIRE_NET_DEVICE}
  brctl delbr ${LOCAL_BRIDGE_NET_DEVICE}
}

setup_iptables() {
  echo '1' > /proc/sys/net/ipv4/ip_forward
  iptables --table nat --append POSTROUTING --out-interface ${REMOTE_WIFI_NET_DEVICE} -j MASQUERADE -s ${LOCAL_IP_NETWORK}
  iptables --append FORWARD -s ${LOCAL_IP_NETWORK} -j ACCEPT
  iptables --append FORWARD -d ${LOCAL_IP_NETWORK} -j ACCEPT -m conntrack --ctstate ESTABLISHED,RELATED -i ${REMOTE_WIFI_NET_DEVICE}
}

tear_down_iptables() {
  iptables --table nat --delete POSTROUTING --out-interface ${REMOTE_WIFI_NET_DEVICE} -j MASQUERADE -s ${LOCAL_IP_NETWORK}
  iptables --delete FORWARD -s ${LOCAL_IP_NETWORK} -j ACCEPT
  iptables --delete FORWARD -d ${LOCAL_IP_NETWORK} -j ACCEPT -m conntrack --ctstate ESTABLISHED,RELATED -i ${REMOTE_WIFI_NET_DEVICE}
}

start() {
  build_bridge
  setup_iptables
  service hostapd start
  service dnsmasq start
}

stop() {
  service hostapd stop
  service dnsmasq stop
  tear_down_iptables
  tear_down_bridge
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    start
    ;;
  *)
    echo "Usage: /etc/init.d/$NAME {start|stop|restart}" >&2
    exit 3
    ;;
esac

exit 0

