#!/bin/bash

# sleep for net configs to take effect
sleep 30s
# restart network services in case nat wasn't fully there
sudo systemctl status NetworkManager.service

# Install some software
sudo yum update -y
sudo yum install wget -y
sudo yum install unzip -y

# Create some files to hold some info for us
touch /tmp/consul-version
touch /tmp/my-ip

# configure consul user
sudo mkdir -p /etc/consul.d
sudo useradd --system --home /etc/consul.d --shell /bin/false consul

# Downloading Consul
sudo wget http://${consul_download_url} -O /tmp/consul.zip
sudo unzip /tmp/consul.zip -d /usr/local/bin
sudo chown root:root /usr/local/bin/consul

# more config
sudo mkdir --parents /opt/consul
sudo chown --recursive consul:consul /opt/consul

# set up systemd
sudo cat << EOF >> /tmp/consul.service
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
Type=notify
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/usr/local/bin/consul reload
ExecStop=/usr/local/bin/consul leave
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
sudo mv /tmp/consul.service /etc/systemd/system/

# set up consul.hcl
sudo touch /etc/systemd/system/consul.service
sudo cat << EOF >> /tmp/consul.hcl
{
  "datacenter": "${data_center}",
  "data_dir": "/opt/consul",
  "encrypt": "${encrypt_key}",
  "log_level": "INFO",
  "retry_join": ["provider=gce project_name=hashi-project tag_value=${consul_join_tag}"],

  "server": true,
  "ui": true
}

EOF
sudo mv /tmp/consul.hcl /etc/consul.d
sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/server.hcl
sudo systemctl enable consul
sudo systemctl start consul


export IP_INTERNAL=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
echo $IP_INTERNAL >> /tmp/my-ip
sleep 30s

sudo wget http://${consul_download_url} -O /tmp/consul.zip
echo "Finished script" >> /tmp/consul-version
