#!/bin/bash

sleep 30s
sudo systemctl status NetworkManager.service
sudo yum update -y
sudo yum install wget -y
sudo yum install unzip -y
sleep 30s
touch /tmp/consul-version
touch /tmp/my-ip

export IP_INTERNAL=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
echo $IP_INTERNAL >> /tmp/my-ip
sleep 30s

sudo wget http://${consul_download_url} -O /tmp/consul.zip
echo "Finished script" >> /tmp/consul-version
