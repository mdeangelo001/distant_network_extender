#! /bin/bash

LOCAL_WIFI_NET_DEVICE=wlan0
LOCAL_WIRE_NET_DEVICE=eth0
LOCAL_BRIDGE_NET_DEVICE=br0
LOCAL_IP_ADDRESS=172.23.13.1/24 
LOCAL_IP_NETWORK=172.23.13.0/24 
LOCAL_WIFI_CHANNEL=3
LOCAL_SSID=farpoint_nomap
LOCAL_DOMAIN=miked.local
DHCP_RANGE=172.23.13.16,172.23.13.63,72h
DHCP_OPTION1=option:router,172.23.13.1
REMOTE_WIFI_NET_DEVICE=wlan1

generate_hostapd_conf() {
cat << EOF > /etc/hostapd/hostapd.conf 
interface=${LOCAL_WIFI_NET_DEVICE}
bridge=${LOCAL_BRIDGE_NET_DEVICE}
driver=nl80211
channel=${LOCAL_WIFI_CHANNEL}
logger_syslog=-1
logger_syslog_level=2
logger_stdout=-1
logger_stdout_level=2
debug=0
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
ssid=${LOCAL_SSID}
auth_algs=3
eapol_key_index_workaround=0
eap_server=0
wpa=3
wpa_psk_file=/etc/hostapd/wpa_psk
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
EOF
}

generate_dnsmasq_conf() {
cat << EOF > /etc/dnsmasq.conf 
interface=${LOCAL_BRIDGE_NET_DEVICE}
domain-needed
bogus-priv
no-poll
server=8.8.8.8
server=8.8.4.4
local=/${LOCAL_DOMAIN}/
no-hosts
addn-hosts=/etc/dnsmasq.d/hosts.conf
expand-hosts
domain=miked.local
dhcp-range=${DHCP_RANGE}
dhcp-option=${DHCP_OPTION1}
dhcp-option=46,8           # netbios node type
EOF
}

build_bridge() {
  ip addr flush dev ${LOCAL_WIFI_NET_DEVICE}
  #ip link set ${LOCAL_WIFI_NET_DEVICE} down
  iw dev ${LOCAL_WIFI_NET_DEVICE} set 4addr on
  #ip link set ${LOCAL_WIFI_NET_DEVICE} up
  brctl addbr ${LOCAL_BRIDGE_NET_DEVICE}
  brctl addif ${LOCAL_BRIDGE_NET_DEVICE} ${LOCAL_WIFI_NET_DEVICE}
  ip addr flush dev ${LOCAL_WIRE_NET_DEVICE}
  brctl addif ${LOCAL_BRIDGE_NET_DEVICE} ${LOCAL_WIRE_NET_DEVICE}
  ip link set ${LOCAL_BRIDGE_NET_DEVICE} up
  ip addr add ${LOCAL_IP_ADDRESS} dev ${LOCAL_BRIDGE_NET_DEVICE}
}

tear_down_bridge() {
  ip addr flush dev ${LOCAL_BRIDGE_NET_DEVICE}
  ip link set ${LOCAL_BRIDGE_NET_DEVICE} down
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
  generate_hostapd_conf
  service hostapd start
  generate_dnsmasq_conf
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

