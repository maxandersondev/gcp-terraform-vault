#!/bin/bash

# sleep for net configs to take effect
sleep 90s
# restart network services in case nat wasn't fully there
#sudo systemctl status NetworkManager.service

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

# configure vault user
sudo mkdir -p /etc/vault.d
sudo useradd --system --home /etc/vault.d --shell /bin/false vault

# Downloading Consul
sudo wget http://${consul_download_url} -O /tmp/consul.zip
sudo unzip /tmp/consul.zip -d /usr/local/bin
sudo chown root:root /usr/local/bin/consul

# Downloading Vault
sudo wget http://${vault_download_url} -O /tmp/vault.zip
sudo unzip /tmp/vault.zip -d /usr/local/bin
sudo chown root:root /usr/local/bin/vault

# more config
sudo mkdir --parents /opt/consul/data
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

sudo cat << EOF >> /tmp/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF
sudo mv /tmp/vault.service /etc/systemd/system/

# get IP
export IP_INTERNAL=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
echo $IP_INTERNAL >> /tmp/my-ip

# set up consul.hcl
sudo cat << EOF >> /tmp/consul.hcl

datacenter  = "${data_center}"
data_dir      = "/opt/consul/data"
encrypt       = "${encrypt_key}"
log_level     = "INFO"
advertise_addr = "$IP_INTERNAL"
retry_join    = ["provider=gce project_name=hashi-project tag_value=${consul_join_tag}"]

performance {
  raft_multiplier = 1
}

server        = false
bootstrap_expect = 3
ui            = true
addresses {
    http      = "0.0.0.0"
}
EOF
sudo mv /tmp/consul.hcl /etc/consul.d
sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/consul.hcl
sudo systemctl enable consul
sudo systemctl start consul

# set up vault.hcl

sudo cat << EOF >> /tmp/vault.hcl
storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault"
}

listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = 1
}

telemetry {
  statsite_address = "127.0.0.1:8125"
  disable_hostname = true
}

EOF
sudo setcap cap_ipc_lock=+ep $(readlink -f $(which vault))
sudo mv /tmp/vault.hcl /etc/vault.d
sudo chown --recursive vault:vault /etc/vault.d
sudo chmod 640 /etc/vault.d/vault.hcl
sudo systemctl enable vault
# sudo systemctl start vault

echo "Finished script" >> /tmp/vault-status
