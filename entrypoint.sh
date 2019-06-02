#!/bin/sh

if [ ! -f /etc/squid/ssl_cert/CA.pem ]; then
    echo 'Cert not found, generating new one...'
    openssl req -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 -extensions v3_ca -keyout /etc/squid/ssl_cert/CA.pem -out /etc/squid/ssl_cert/CA.pem -subj "/C=CN/ST=Beijing/L=Chaoyang/O=Example Organization/CN=Example Certificate Authority"
else
    echo 'Cert found, skipping...'
fi
openssl x509 -in /etc/squid/ssl_cert/CA.pem -out /etc/squid/ssl_cert/http/ca.cert

echo 'Clean dynamic certs cache and recreate cache directory'
sslcrtd_program=$(grep sslcrtd_program /etc/squid/squid.conf | awk '{print $2}')
rm -rf /var/lib/ssl_db
$sslcrtd_program -c -s /var/lib/ssl_db -M 4MB

echo 'Check missing swap directory'
/usr/sbin/squid -z -F

echo 'Make sure directory permission'
chown -R squid:squid /etc/squid /var/lib/ssl_db /var/spool/squid
chmod -R 0700 /etc/squid/ssl_cert

echo 'Start supervisor'
exec $@
