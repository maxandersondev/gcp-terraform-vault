#/bin/bash

touch /tmp/consul-version
export IP_INTERNAL=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')echo "${consul_version}" >> /tmp/consul-version
echo "${$IP_INTERNAL}" >> /tmp/consul-version
echo "${consul_version}" >> /tmp/consul-version