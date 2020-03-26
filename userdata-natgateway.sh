#!/bin/bash
ifconfig eth1 172.18.1.10/24 up
route add -net 172.20.0.0/14 gw 172.18.1.1
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -A FORWARD -o eth0 -i eth1 -s 172.20.0.0/14 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -F POSTROUTING
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Add Inbout NAT for Web Servers
iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 8081 -j DNAT --to 172.21.5.20:80
iptables -A FORWARD -p tcp -d 172.21.5.20 --dport 80 -j ACCEPT
iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 8082 -j DNAT --to 172.22.5.20:80
iptables -A FORWARD -p tcp -d 172.22.5.20 --dport 80 -j ACCEPT
iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 8083 -j DNAT --to 172.23.5.20:80
iptables -A FORWARD -p tcp -d 172.23.5.20 --dport 80 -j ACCEPT

# Set webservers in the hosts file
echo "172.21.5.20      vpc1-web1" | sudo tee -a /etc/hosts
echo "172.22.5.20      vpc2-web1" | sudo tee -a /etc/hosts
echo "172.23.5.20      vpc3-web1" | sudo tee -a /etc/hosts