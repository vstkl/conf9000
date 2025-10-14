#!/bin/bash

# Update systému a instalace potřebných balíků
apt update
apt install -y openssl apache2

# Nastavení adresářů
mkdir -p /home/student/company/{newcerts,private}
chmod 700 /home/student/company/private
cd /home/student/company || exit 1

# Vytvoření vlastního konfiguračního souboru OpenSSL
cat > openssl.cnf <<'EOF'
[ req ]
distinguished_name  = req_distinguished_name
prompt = no

[ req_distinguished_name ]
C  = CZ
ST = .
L  = Ostrava
O  = VSB
OU = KAT440
CN = Firma CA

[ v3_req ]
subjectAltName = @alt_names

[ alt_names ]
# SAN bude doplněno při generování certifikátu
EOF

# Vytvoření certifikační autority (CA) s heslem EB210 a 4096bit klíčem, platnost 10 let
openssl req -config openssl.cnf -new -x509 \
-newkey rsa:4096 -days 3650 \
-keyout ./private/ca.key -out ca.crt -passout pass:EB210

chmod 400 ./private/ca.key

# Vytvoření CSR (Certificate Signing Request) pro server
read -rp "Zadej IP adresu serveru: " SERVER_IP

cat > san.cnf <<EOF
subjectAltName=IP:${SERVER_IP}
EOF

# Vytvoření serverového klíče (2048 bitů, bez hesla) a CSR
openssl req -config openssl.cnf -new \
-newkey rsa:2048 -nodes \
-keyout ./private/server.key -out server.csr

# Podepsání serverového CSR CA certifikátem, platnost 1 rok
openssl x509 -req -days 365 \
-in server.csr -CA ca.crt -CAkey ./private/ca.key -CAcreateserial \
-extfile san.cnf -out ./newcerts/server.crt -passin pass:EB210

# Vytvoření PEM souboru kombinací soukromého klíče a certifikátu
cat ./private/server.key ./newcerts/server.crt > server.pem

# Vytvoření samostatného VirtualHost souboru pro Apache SSL
cat > /etc/apache2/sites-available/company-ssl.conf <<EOF
<VirtualHost *:443>
    ServerName ${SERVER_IP}
    SSLEngine on
    SSLCertificateFile "/home/student/company/newcerts/server.crt"
    SSLCertificateKeyFile "/home/student/company/private/server.key"
</VirtualHost>
EOF

# Aktivace SSL modulu a nové site
a2enmod ssl
a2ensite company-ssl.conf

# Restart Apache
systemctl restart apache2
systemctl status apache2
