#!/bin/bash
ifconfig eth1 172.18.1.10/24 up
route add -net 172.20.0.0/14 gw 172.18.1.1
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -A FORWARD -o eth0 -i eth1 -s 172.20.0.0/14 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -F POSTROUTING
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "172.21.5.20      vpc1-web1" | sudo tee -a /etc/hosts
echo "172.22.5.20      vpc2-web1" | sudo tee -a /etc/hosts
echo "172.23.5.20      vpc3-web1" | sudo tee -a /etc/hosts