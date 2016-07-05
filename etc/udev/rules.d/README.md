You can find info about the properties of your card by first identifying the device.
The command `lsusb` will show all the currently installed USB devices.

```
$ lsusb
Bus 004 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
Bus 002 Device 002: ID 0cf3:9271 Atheros Communications, Inc. AR9271 802.11n
Bus 002 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 003 Device 002: ID 046d:c52b Logitech, Inc. Unifying Receiver
Bus 003 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
```

Now the command `udevadm info /dev/bus/usb/{BUS NUM}/{DEVICE NUM}` can be used to query
information about the device.

```
$ udevadm info /dev/bus/usb/002/002
P: /devices/soc.0/1c1b000.ehci1-controller/usb2/2-1
N: bus/usb/002/002
E: BUSNUM=002
E: DEVNAME=/dev/bus/usb/002/002
E: DEVNUM=002
E: DEVPATH=/devices/soc.0/1c1b000.ehci1-controller/usb2/2-1
E: DEVTYPE=usb_device
E: DRIVER=usb
E: ID_BUS=usb
E: ID_MODEL=USB2.0_WLAN
E: ID_MODEL_ENC=USB2.0\x20WLAN
E: ID_MODEL_FROM_DATABASE=AR9271 802.11n
E: ID_MODEL_ID=9271
E: ID_REVISION=0108
E: ID_SERIAL=ATHEROS_USB2.0_WLAN_12345
E: ID_SERIAL_SHORT=12345
E: ID_USB_INTERFACES=:ff0000:
E: ID_VENDOR=ATHEROS
E: ID_VENDOR_ENC=ATHEROS
E: ID_VENDOR_FROM_DATABASE=Atheros Communications, Inc.
E: ID_VENDOR_ID=0cf3
E: MAJOR=189
E: MINOR=129
E: PRODUCT=cf3/9271/108
E: SUBSYSTEM=usb
E: TYPE=255/255/255
E: USEC_INITIALIZED=10370234
```

This gives us information about the USB interface to the network card, but not information
about the network card itself. To get that, we use the `P:` entry above. That is the PATH
to this device under the `/sys` filesystem.

When we do `$ ls /sys/devices/soc.0/1c1b000.ehci1-controller/usb2/2-1` we find a subdirectory
'2-1:1.0' that represents the first 'port' of the USB device. A single USB interface can 
control multiple devices by assigning each a different port.

When we do `$ ls  /sys/devices/soc.0/1c1b000.ehci1-controller/usb2/2-1/2-1\:1.0/` we find
it has a subdirectory 'net' and that net has a subdirectory with the name of our 
actual network device. We can use that path to query all the attributes of the device
using `udevadm info` and `udevadm info --attribute-walk`.

```
$ udevadm info /sys/devices/soc.0/1c1b000.ehci1-controller/usb2/2-1/2-1\:1.0/net/wlan1 
P: /devices/soc.0/1c1b000.ehci1-controller/usb2/2-1/2-1:1.0/net/wlan1
E: DEVPATH=/devices/soc.0/1c1b000.ehci1-controller/usb2/2-1/2-1:1.0/net/wlan1
E: DEVTYPE=wlan
E: ID_BUS=usb
E: ID_MM_CANDIDATE=1
E: ID_MODEL=USB2.0_WLAN
E: ID_MODEL_ENC=USB2.0\x20WLAN
E: ID_MODEL_FROM_DATABASE=AR9271 802.11n
E: ID_MODEL_ID=9271
E: ID_NET_DRIVER=ath9k_htc
E: ID_NET_LINK_FILE=/lib/systemd/network/99-default.link
E: ID_NET_NAME_MAC=wlxec086b132771
E: ID_OUI_FROM_DATABASE=TP-LINK TECHNOLOGIES CO.,LTD.
E: ID_PATH=platform-1c1b000.ehci1-controller-usb-0:1:1.0
E: ID_PATH_TAG=platform-1c1b000_ehci1-controller-usb-0_1_1_0
E: ID_REVISION=0108
E: ID_SERIAL=ATHEROS_USB2.0_WLAN_12345
E: ID_SERIAL_SHORT=12345
E: ID_TYPE=generic
E: ID_USB_CLASS_FROM_DATABASE=Vendor Specific Class
E: ID_USB_DRIVER=ath9k_htc
E: ID_USB_INTERFACES=:ff0000:
E: ID_USB_INTERFACE_NUM=00
E: ID_USB_PROTOCOL_FROM_DATABASE=Vendor Specific Protocol
E: ID_USB_SUBCLASS_FROM_DATABASE=Vendor Specific Subclass
E: ID_VENDOR=ATHEROS
E: ID_VENDOR_ENC=ATHEROS
E: ID_VENDOR_FROM_DATABASE=Atheros Communications, Inc.
E: ID_VENDOR_ID=0cf3
E: IFINDEX=5
E: INTERFACE=wlan1
E: SUBSYSTEM=net
E: SYSTEMD_ALIAS=/sys/subsystem/net/devices/wlan1 /sys/subsystem/net/devices/wlan1
E: TAGS=:systemd:
E: USEC_INITIALIZED=14330617
```
```
$ udevadm info --attribute-walk /sys/devices/soc.0/1c1b000.ehci1-controller/usb2/2-1/2-1\:1.0/net/wlan1
```
Udevadm info starts with the device specified by the devpath and then
walks up the chain of parent devices. It prints for every device
found, all possible attributes in the udev rules key format.
A rule to match, can be composed by the attributes of the device
and the attributes from one single parent device.
```
  looking at device '/devices/soc.0/1c1b000.ehci1-controller/usb2/2-1/2-1:1.0/net/wlan1':
    KERNEL=="wlan1"
    SUBSYSTEM=="net"
    DRIVER==""
    ATTR{addr_assign_type}=="0"
    ATTR{addr_len}=="6"
    ATTR{address}=="xx:xx:xx:xx:xx:xx"
    ATTR{broadcast}=="ff:ff:ff:ff:ff:ff"
    ATTR{carrier}=="1"
    ATTR{dev_id}=="0x0"
    ATTR{dormant}=="0"
    ATTR{flags}=="0x1003"
    ATTR{ifalias}==""
    ATTR{ifindex}=="5"
    ATTR{iflink}=="5"
    ATTR{link_mode}=="1"
    ATTR{mtu}=="1500"
    ATTR{netdev_group}=="0"
    ATTR{operstate}=="up"
    ATTR{tx_queue_len}=="1000"
    ATTR{type}=="1"

  looking at parent device '/devices/soc.0/1c1b000.ehci1-controller/usb2/2-1/2-1:1.0':
    KERNELS=="2-1:1.0"
    SUBSYSTEMS=="usb"
    DRIVERS=="ath9k_htc"
    ATTRS{bAlternateSetting}==" 0"
    ATTRS{bInterfaceClass}=="ff"
    ATTRS{bInterfaceNumber}=="00"
    ATTRS{bInterfaceProtocol}=="00"
    ATTRS{bInterfaceSubClass}=="00"
    ATTRS{bNumEndpoints}=="06"
    ATTRS{supports_autosuspend}=="0"

  looking at parent device '/devices/soc.0/1c1b000.ehci1-controller/usb2/2-1':
    KERNELS=="2-1"
    SUBSYSTEMS=="usb"
    DRIVERS=="usb"
    ATTRS{authorized}=="1"
    ATTRS{avoid_reset_quirk}=="0"
    ATTRS{bConfigurationValue}=="1"
    ATTRS{bDeviceClass}=="ff"
    ATTRS{bDeviceProtocol}=="ff"
    ATTRS{bDeviceSubClass}=="ff"
    ATTRS{bMaxPacketSize0}=="64"
    ATTRS{bMaxPower}=="500mA"
    ATTRS{bNumConfigurations}=="1"
    ATTRS{bNumInterfaces}==" 1"
    ATTRS{bcdDevice}=="0108"
    ATTRS{bmAttributes}=="80"
    ATTRS{busnum}=="2"
    ATTRS{configuration}==""
    ATTRS{devnum}=="2"
    ATTRS{devpath}=="1"
    ATTRS{idProduct}=="9271"
    ATTRS{idVendor}=="0cf3"
    ATTRS{ltm_capable}=="no"
    ATTRS{manufacturer}=="ATHEROS"
    ATTRS{maxchild}=="0"
    ATTRS{product}=="USB2.0 WLAN"
    ATTRS{quirks}=="0x0"
    ATTRS{removable}=="unknown"
    ATTRS{serial}=="12345"
    ATTRS{speed}=="480"
    ATTRS{urbnum}=="6283663"
    ATTRS{version}==" 2.00"

  looking at parent device '/devices/soc.0/1c1b000.ehci1-controller/usb2':
    KERNELS=="usb2"
    SUBSYSTEMS=="usb"
    DRIVERS=="usb"
    ATTRS{authorized}=="1"
    ATTRS{authorized_default}=="1"
    ATTRS{avoid_reset_quirk}=="0"
    ATTRS{bConfigurationValue}=="1"
    ATTRS{bDeviceClass}=="09"
    ATTRS{bDeviceProtocol}=="00"
    ATTRS{bDeviceSubClass}=="00"
    ATTRS{bMaxPacketSize0}=="64"
    ATTRS{bMaxPower}=="0mA"
    ATTRS{bNumConfigurations}=="1"
    ATTRS{bNumInterfaces}==" 1"
    ATTRS{bcdDevice}=="0310"
    ATTRS{bmAttributes}=="e0"
    ATTRS{busnum}=="2"
    ATTRS{configuration}==""
    ATTRS{devnum}=="1"
    ATTRS{devpath}=="0"
    ATTRS{idProduct}=="0002"
    ATTRS{idVendor}=="1d6b"
    ATTRS{ltm_capable}=="no"
    ATTRS{manufacturer}=="Linux 3.10.101-4-pine64-longsleep ehci_hcd"
    ATTRS{maxchild}=="1"
    ATTRS{product}=="SW USB2.0 'Enhanced' Host Controller (EHCI) Driver"
    ATTRS{quirks}=="0x0"
    ATTRS{removable}=="unknown"
    ATTRS{serial}=="sunxi-ehci"
    ATTRS{speed}=="480"
    ATTRS{urbnum}=="22"
    ATTRS{version}==" 2.00"

  looking at parent device '/devices/soc.0/1c1b000.ehci1-controller':
    KERNELS=="1c1b000.ehci1-controller"
    SUBSYSTEMS=="platform"
    DRIVERS=="sunxi-ehci"
    ATTRS{companion}==""
    ATTRS{ed_test}==""
    ATTRS{ehci_enable}=="ehci:1, probe:1"
    ATTRS{phy_range}=="rate:0x14"
    ATTRS{phy_threshold}=="threshold:0x3"
    ATTRS{uframe_periodic_max}=="100"

  looking at parent device '/devices/soc.0':
    KERNELS=="soc.0"
    SUBSYSTEMS=="platform"
    DRIVERS==""
```
 
Values reported by udevadm prepended with an `E:` should be matched in the udev rule like
`ENV{DEVNAME}="/dev/bus/usb/002/002`"

