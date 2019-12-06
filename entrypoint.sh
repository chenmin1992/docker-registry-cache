#!/bin/bash

sed -i 's/^socks/#socks/g' /etc/proxychains/proxychains.conf
sed -i 's/^http/#http/g' /etc/proxychains/proxychains.conf
if [ ! -z $PROXY ]; then
    proto=$(echo $PROXY | awk -F'[:/]' '{print $1}')
    addr=$(echo $PROXY | awk -F'[:/]' '{print $4}')
    port=$(echo $PROXY | awk -F'[:/]' '{print $5}')
    if [ ! -z $proto -a ! -z $addr -a ! -z $port ]; then
        echo "PROXY $PROXY is set, using outter proxy: $proto $addr $port"
        echo "$proto $addr $port" >> /etc/proxychains/proxychains.conf
    else
        echo 'PROXY $PROXY is set,BUT CAN NOT BE PARSED, continue using internal ss-local'
    fi
else
    echo "PROXY $PROXY is not set, using internal ss-local"
    echo 'http 127.0.0.1 8118' >> /etc/proxychains/proxychains.conf
fi

if [ ! -z $DOMAINS ]; then
    array=(${DOMAINS//,/ })
    for domain in ${array[*]}
    do
        grep "acl sites_allowed url_regex -i ${domain//./\\\\.}" /etc/squid/squid.conf >/dev/null || sed -i "/user defined sites/aacl sites_allowed url_regex -i ${domain//./\\\\.}" /etc/squid/squid.conf
    done
fi

if [ ! -f /etc/squid/ssl_cert/CA.pem ]; then
    echo 'Cert not found, generating new one...'
    openssl req -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 -extensions v3_ca -keyout /etc/squid/ssl_cert/CA.pem -out /etc/squid/ssl_cert/CA.pem -subj "/C=CN/ST=Beijing/L=Chaoyang/O=Example Organization/CN=Example Certificate Authority"
else
    echo 'Cert found, skipping...'
fi
openssl x509 -in /etc/squid/ssl_cert/CA.pem -out /etc/squid/ssl_cert/http/ca.crt

echo 'Clean dynamic certs cache and recreate cache directory'
sslcrtd_program=$(grep sslcrtd_program /etc/squid/squid.conf | awk '{print $2}')
rm -rf /var/lib/ssl_db
$sslcrtd_program -c -s /var/lib/ssl_db -M 4MB

echo 'Checking missing swap directories'
/usr/sbin/squid -z -N -F

echo 'Make sure directory permission'
chown -R squid:squid /etc/squid /var/lib/ssl_db /var/spool/squid
chmod -R 0700 /etc/squid/ssl_cert

echo 'Start supervisor'
exec $@
