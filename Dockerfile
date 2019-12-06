FROM alpine

LABEL maintainer="klutz <781022537@qq.com>"

ARG TZ="Asia/Shanghai"

ENV TZ ${TZ}

ADD . /tmp/install

RUN set -ex && cd /tmp && \
    sed -i 's#dl-cdn.alpinelinux.org#mirror.tuna.tsinghua.edu.cn#g' /etc/apk/repositories && \
    apk add --update --no-cache bash supervisor squid proxychains-ng privoxy pcre openssl libsodium zlib curl git gcc autoconf automake build-base c-ares-dev libev-dev libtool linux-headers mbedtls-dev pcre-dev openssl-dev libsodium-dev zlib-dev tzdata perl && \
    cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} > /etc/timezone && \
    # compile install shadowsocksr-libev
    cd /tmp && \
    git clone https://github.com/chenmin1992/shadowsocksr-libev.git && cd shadowsocksr-libev && \
    ./autogen.sh && ./configure --prefix=/usr --disable-documentation && make install && cd /tmp && \
    mkdir /etc/shadowsocks && \
    cp /tmp/install/ssr.config.json.example /etc/shadowsocks/config.json && \
    # privoxy
    curl -skLO https://raw.github.com/zfl9/gfwlist2privoxy/master/gfwlist2privoxy && \
    bash gfwlist2privoxy 127.0.0.1:1080 && \
    mv gfwlist.action /etc/privoxy/ && \
    echo 'actionsfile gfwlist.action' >> /etc/privoxy/config && \
    chown -R privoxy:privoxy /etc/privoxy && \
    # proxychains
    sed -i 's/^socks/#socks/g' /etc/proxychains/proxychains.conf && \
    sed -i 's/^http/#http/g' /etc/proxychains/proxychains.conf && \
    # squid
    cp /tmp/install/squid-4.x.conf /etc/squid/squid.conf && \
    mkdir -p /etc/squid/ssl_cert/http && \
    cp /tmp/install/cert_delivery.py /etc/squid/ssl_cert/http/http.py && \
    echo -n > /etc/squid/ssl_cert/http/index.html && \
    rm -rf /var/lib/ssl_db && \
    mkdir -p /var/lib/ssl_db && \
    mkdir -p /var/cache/squid && \
    chown -R squid:squid /etc/squid /var/lib/ssl_db /var/cache/squid && \
    chmod -R 0700 /etc/squid/ssl_cert && \
    # supervisor
    mkdir /etc/supervisor.d && \
    cp /tmp/install/docker-cache.ini /etc/supervisor.d/docker-cache.ini && \
    cp /tmp/install/entrypoint.sh /entrypoint.sh && chmod +x /entrypoint.sh && \
    # clean up
    apk del git gcc autoconf automake build-base c-ares-dev libev-dev libtool linux-headers mbedtls-dev pcre-dev openssl-dev libsodium-dev zlib-dev tzdata perl && \
    apk add --no-cache rng-tools $(scanelf --needed --nobanner /usr/bin/ss-* | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' | sort -u) && \
    rm -rf /tmp/*

VOLUME /var/spool/squid

EXPOSE 3128 80

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/usr/bin/supervisord","-n","-c","/etc/supervisord.conf"]
