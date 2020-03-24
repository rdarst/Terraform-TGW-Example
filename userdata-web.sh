#!/bin/bash
sudo apt update
sudo apt -y install docker docker.io
sudo docker run -d -p 80:80 -p 443:443 -h web3 -e APPSERVER="http://172.21.102.23:8080" benpiper/mtwa:web