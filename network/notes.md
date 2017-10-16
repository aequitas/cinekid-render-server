WAC:
https//172.16.60.2 Cisco/Cinekid2012

Kabels:
Switch1:25 -> WAC:poort links 1 whatever
Switch1:26 -> Core:0 (helemaal rechts)
Uplink -> Core:GE0/0
Switch1:1 -> Management (vlan16)

wireless accesspoints untagged vlan20

# Troubleshootings

## AP's won't connect to Controller

Common problems:

- AP is in the wrong network, need to be in vlan20 (untagged) 172.16.20.0/24 (port 13-22 (13-24 on some switches)).
- AP vendor certificate is expired in oktober 2017 -> solution 1
- Controller time after reset is to early for AP vendor certificates to be valid -> solution 1

Notes:

AP's and/or controller have manufacturer installed certificates (MIC) with a 10 year validity. Devices where probably produced around 2006 (based on the date to which the WLC resets to after reboot). Initial communication between LAP and WLC (DTLS) might not be possible due to date mismatch on the certificates and the controller causing the certificates to be considered expired (or not yet valid if a newer certificate is installed). It is unknown if LAP's obtain new certificates with a updated expiry date. LAP's seen to be happy to join a 2006 WLC after being connected to a 2016 WLC (which is powercycled and restored to 2006) while LAP's who had not been connected this year don't want to connect.

Context:

- AP Type LAP (lightweight access point): AIR-LAP 1131AG-3
- Controller type WLC (wireless lan controller): WLC4400
- https://www.cisco.com/c/en/us/td/docs/wireless/access_point/1130/installation/guide/1130-TD-Book-Wrapper/113h_c3.html#wp1030793
- http://www.networkoc.net/cisco-wlc-bad-certificate-alert-received-from-peer/
- http://nexp.com.ua/technologies/wireless/cisco-wlc-4400-catastrophic-bug/

### Solution 1 - make WLC live in the past to mitigate certificate issues

Set controller time to somewhere around oktober 2016

Steps:

- https://172.16.60.2
- Login
- Commands
- Set Time
- Year -> 2016
- Set Date and Time

### Sniff air discovery traffic

AP<->Controller traffic excluding own host:

    tcpdump -i en3 net 172.16.20.0/24 and not host 172.16.20.31 -lnA

syslog broadcasts by AP's:

    tcpdump -i en3 net 172.16.20.0/24 and port 514 -lnA

#### failing boot

    14:31:30.821054 IP 172.16.20.1.67 > 255.255.255.255.68: BOOTP/DHCP, Reply, length 300
    14:31:30.831540 IP 172.16.20.1.67 > 255.255.255.255.68: BOOTP/DHCP, Reply, length 300
    14:31:30.831860 ARP, Reply 172.16.20.32 is-at 00:1b:54:d1:e6:40, length 46
    14:31:33.944008 ARP, Reply 172.16.20.32 is-at 00:1b:54:d1:e6:40, length 46
    14:31:54.625223 ARP, Request who-has 172.16.20.1 tell 172.16.20.32, length 46
    14:31:55.633494 IP 172.16.20.32.7781 > 255.255.255.255.5246: UDP, length 123
    14:32:06.940442 IP 172.16.20.32.61248 > 255.255.255.255.514: SYSLOG kernel.error, length: 109
    14:32:06.940718 IP 172.16.20.32.61248 > 255.255.255.255.514: SYSLOG kernel.error, length: 107
    14:32:28.318856 IP 172.16.20.32.61248 > 255.255.255.255.514: SYSLOG kernel.error, length: 106
    14:32:28.319260 IP 172.16.20.32.61248 > 255.255.255.255.514: SYSLOG kernel.error, length: 106


    ~ $ tcpdump -i en3 net 172.16.20.0/24 and port 514 -lnA
    tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
    listening on en3, link-type EN10MB (Ethernet), capture size 262144 bytes
    14:35:19.193186 IP 172.16.20.32.60119 > 255.255.255.255.514: SYSLOG kernel.error, length: 109
    E..........3... .........u..<3>23: AP:001b.54d1.e640: *Oct 14 14:35:44.308: %CAPWAP-3-ERRORLOG: Bad certificate alert received from peer.
    14:35:19.193328 IP 172.16.20.32.60119 > 255.255.255.255.514: SYSLOG kernel.error, length: 107
    E..........4... .........s..<3>24: AP:001b.54d1.e640: *Oct 14 14:35:44.309: %CAPWAP-3-ERRORLOG: Invalid event 38 & state 3 combination.
    14:35:41.886273 IP 172.16.20.32.60119 > 255.255.255.255.514: SYSLOG kernel.error, length: 106
    E..........4... .........r..<3>25: AP:001b.54d1.e640: *Oct 14 14:36:06.047: %LINK-3-UPDOWN: Interface Dot11Radio1, changed state to up
    14:35:41.886672 IP 172.16.20.32.60119 > 255.255.255.255.514: SYSLOG kernel.error, length: 106
    E..........3... .........r..<3>26: AP:001b.54d1.e640: *Oct 14 14:36:06.081: %LINK-3-UPDOWN: Interface Dot11Radio0, changed state to up

#### happy boot

    11:34:09.060328 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 106
    E....%.....	...(.........r..<3>60: AP:001b.5497.7d06: *Jan  2 13:23:17.188: %LINK-3-UPDOWN: Interface Dot11Radio0, changed state to up
    11:34:09.060657 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 106
    E....&.........(.........r..<3>61: AP:001b.5497.7d06: *Jan  2 13:23:17.188: %LINK-3-UPDOWN: Interface Dot11Radio1, changed state to up
    11:34:09.061054 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 108
    E....'.........(.........t..<3>62: AP:001b.5497.7d06: *Jan  2 13:23:17.189: %LINK-3-UPDOWN: Interface Dot11Radio0, changed state to down
    11:34:09.092187 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 106
    E....(.........(.........r..<3>63: AP:001b.5497.7d06: *Jan  2 13:23:17.221: %LINK-3-UPDOWN: Interface Dot11Radio0, changed state to up
    11:34:09.128330 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 106
    E....).........(.........r..<3>64: AP:001b.5497.7d06: *Jan  2 13:23:17.251: %LINK-3-UPDOWN: Interface Dot11Radio1, changed state to up
    11:34:09.128609 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 108
    E....*.........(.........t..<3>65: AP:001b.5497.7d06: *Jan  2 13:23:17.256: %LINK-3-UPDOWN: Interface Dot11Radio0, changed state to down
    11:34:10.153096 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 106
    E....+.........(.........r..<3>66: AP:001b.5497.7d06: *Jan  2 13:23:17.288: %LINK-3-UPDOWN: Interface Dot11Radio0, changed state to up
    11:34:20.858648 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 108
    E....,.........(.........t..<3>67: AP:001b.5497.7d06: *Jan  2 13:23:20.791: %LINK-3-UPDOWN: Interface Dot11Radio1, changed state to down
    11:34:20.858870 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 108
    E....-.........(.........t..<3>68: AP:001b.5497.7d06: *Jan  2 13:23:20.794: %LWAPP-3-CLIENTEVENTLOG: SSID Cinekid-F added to the slot[0]
    11:34:20.874935 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 108
    E..............(.........t..<3>69: AP:001b.5497.7d06: *Jan  2 13:23:20.797: %LWAPP-3-CLIENTEVENTLOG: SSID Cinekid-U added to the slot[0]
    11:34:20.875095 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 108
    E..../.........(.........t..<3>70: AP:001b.5497.7d06: *Jan  2 13:23:20.800: %LWAPP-3-CLIENTEVENTLOG: SSID Cinekid-N added to the slot[0]
    11:34:20.875452 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 108
    E....0.........(.........t..<3>71: AP:001b.5497.7d06: *Jan  2 13:23:20.802: %LWAPP-3-CLIENTEVENTLOG: SSID Cinekid-F added to the slot[1]
    11:34:20.875831 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 108
    E....1.........(.........t..<3>72: AP:001b.5497.7d06: *Jan  2 13:23:20.805: %LWAPP-3-CLIENTEVENTLOG: SSID Cinekid-U added to the slot[1]
    11:34:20.876197 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 108
    E....2.........(.........t..<3>73: AP:001b.5497.7d06: *Jan  2 13:23:20.807: %LWAPP-3-CLIENTEVENTLOG: SSID Cinekid-N added to the slot[1]
    11:34:20.949478 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 106
    E....3.........(.........r..<3>74: AP:001b.5497.7d06: *Jan  2 13:23:20.886: %LINK-3-UPDOWN: Interface Dot11Radio1, changed state to up
    11:34:20.949633 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 108
    E....4.........(.........t..<3>75: AP:001b.5497.7d06: *Jan  2 13:23:20.895: %LINK-3-UPDOWN: Interface Dot11Radio0, changed state to down
    11:34:20.989387 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 106
    E....5.........(.........r..<3>76: AP:001b.5497.7d06: *Jan  2 13:23:20.929: %LINK-3-UPDOWN: Interface Dot11Radio0, changed state to up
    11:34:20.989537 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 108
    E....6.........(.........t..<3>77: AP:001b.5497.7d06: *Jan  2 13:23:20.935: %LINK-3-UPDOWN: Interface Dot11Radio1, changed state to down
    11:34:22.015989 IP 172.16.20.40.57489 > 255.255.255.255.514: SYSLOG kernel.error, length: 106
    E....7.........(.........r..<3>78: AP:001b.5497.7d06: *Jan  2 13:23:20.967: %LINK-3-UPDOWN: Interface Dot11Radio1, changed state to up
