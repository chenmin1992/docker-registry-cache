#!/bin/bash

sed -i 's/^socks/#socks/g' /etc/proxychains/proxychains.conf
sed -i 's/^http/#http/g' /etc/proxychains/proxychains.conf
if [ ! -z $PROXY ]; then
    proto=$(echo $PROXY | awk -F'[:/]' '{print $1}')
    addr=$(echo $PROXY | awk -F'[:/]' '{print $4}')
    port=$(echo $PROXY | awk -F'[:/]' '{print $5}')
    if [ ! -z $proto -a ! -z $addr -a ! -z $port ]; then
        echo "PROXY $PROXY is set, using upstream proxy: $proto $addr $port"
        echo "$proto $addr $port" >> /etc/proxychains/proxychains.conf
    else
        echo "PROXY $PROXY is set, BUT CAN NOT BE PARSED, all of http requests will connect DIRECTLY"
    fi
else
    echo 'PROXY is not set, all of http requests will connect DIRECTLY'
fi

if [ ! -z $DOMAINS ]; then
    array=(${DOMAINS//,/ })
    for domain in ${array[*]}
    do
        grep -q "acl sites_allow url_regex -i ${domain//./\\\\.}" /etc/squid/squid.conf || sed -i "/user defined sites/aacl sites_allow url_regex -i ${domain//./\\\\.}" /etc/squid/squid.conf
    done
fi

if [ ! -s /etc/squid/ssl_cert/ca.pem ]; then
    echo 'Cert not found, generating new one...'
    openssl req -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 -keyout /etc/squid/ssl_cert/ca.pem -out /etc/squid/ssl_cert/ca.pem -subj "/C=CN/ST=Beijing/L=Chaoyang/O=Example Organization/CN=Example Certificate Authority" -extensions exts -config <(
cat <<EOF
[req]
distinguished_name = dn
[dn]
[exts]
basicConstraints = critical,CA:TRUE
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
subjectKeyIdentifier = hash
EOF
)
else
    echo 'Cert found, will reuse it...'
fi
openssl x509 -in /etc/squid/ssl_cert/ca.pem -out /opt/http/ca.crt
echo 'Install the ca.crt from http://myip/ca.crt'

echo 'Clean dynamic certs cache'
sslcrtd_program=$(grep sslcrtd_program /etc/squid/squid.conf | awk '{print $2}')
rm -rf /var/lib/ssl_db
$sslcrtd_program -c -s /var/lib/ssl_db -M 4MB

echo 'Checking missing swap directories'
chown -R squid:squid /var/cache/squid
/usr/sbin/squid -z -N -F

echo 'Make sure directory permission'
chown -R squid:squid /etc/squid /var/lib/ssl_db /var/cache/squid
chmod -R 0700 /etc/squid/ssl_cert

echo 'Start supervisor'
/usr/bin/supervisord -n -c /etc/supervisord.conf
