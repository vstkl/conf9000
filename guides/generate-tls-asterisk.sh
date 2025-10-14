#!/bin/bash

# Zeptá se na IP
read -p "Zadej IP adresu pro certifikát: " IP

# Aktualizace a instalace závislostí
sudo apt update
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz
tar -xf asterisk-20-current.tar.gz

# Instalace předpokladů
cd asterisk-20.15.2/contrib/scripts/
sudo ./install_prereq install
cd ../..

# Kompilace a instalace Asterisku
sudo ./configure
make -j 4
sudo make install
sudo make samples
sudo make config

# Smazání výchozího pjsip.conf
sudo rm /etc/asterisk/pjsip.conf

# Certifikáty
sudo mkdir -p /etc/asterisk/keys
wget https://raw.githubusercontent.com/asterisk/asterisk/master/contrib/scripts/ast_tls_cert
chmod +x ast_tls_cert

# Generování serverového certifikátu
sudo ./ast_tls_cert -C $IP -O VSB -d /etc/asterisk/keys

# Generování klientských certifikátů
sudo ./ast_tls_cert -m client -c /etc/asterisk/keys/ca.crt -k /etc/asterisk/keys/ca.key -C 2000.vsb.cz -O "VSB" -d /etc/asterisk/keys -o 2000
sudo ./ast_tls_cert -m client -c /etc/asterisk/keys/ca.crt -k /etc/asterisk/keys/ca.key -C 2001.vsb.cz -O "VSB" -d /etc/asterisk/keys -o 2001

sudo tee /etc/asterisk/pjsip.conf > /dev/null << EOF
[simpletrans]
type=transport
protocol=tls
bind=0.0.0.0:5061
ca_list_file=/etc/asterisk/keys/ca.crt
cert_file=/etc/asterisk/keys/asterisk.crt
priv_key_file=/etc/asterisk/keys/asterisk.key
method=tlsv1_2

[2000]
type = endpoint
context = internal
disallow = all
allow = ulaw
aors = 2000
auth = auth2000
media_encryption=sdes

[2000]
type = aor
max_contacts = 10

[auth2000]
type=auth
auth_type=userpass
password=1234
username=2000

[2001]
type = endpoint
context = internal
disallow = all
allow = ulaw
aors = 2001
auth = auth2001
media_encryption=sdes

[2001]
type = aor
max_contacts = 10

[auth2001]
type=auth
auth_type=userpass
password=1234
username=2001
EOF

# Vytvoření extensions.conf
sudo tee /etc/asterisk/extensions.conf > /dev/null << EOF
[internal]
exten => _200X,1,Dial(PJSIP/\${EXTEN})
EOF

systemctl restart asterisk
systemctl status asterisk













