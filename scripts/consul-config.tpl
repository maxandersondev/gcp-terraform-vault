#!/bin/bash

sudo systemctl status NetworkManager.service
sudo yum update -y
sudo yum install wget -y
sleep 30s
touch /tmp/consul-version
echo "${consul_download_url}" >> /tmp/consul-version
export IP_INTERNAL=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
echo $IP_INTERNAL >> /tmp/consul-version
sleep 30s
echo "sudo wget http://${consul_download_url} -P /tmp" >> /tmp/consul-version
sudo wget "http://${consul_download_url} -P /tmp"
