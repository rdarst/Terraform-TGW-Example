#!/bin/bash
ifconfig eth1 172.20.1.10/24 up
route add -net 172.21.0.0/16 gw 172.20.1.1
route add -net 172.22.0.0/16 gw 172.20.1.1
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -A FORWARD -o eth0 -i eth1 -s 172.21.0.0/16 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -F POSTROUTING
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

