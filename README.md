# docker-registry-cache
docker registry/images cache proxy, with bypass the certain firewall.  
docker registry/images缓存，把docker镜像缓存起来下次就不用再费劲的拉了，可以翻越某防火墙。
## 构建镜像
```
docker build -t docker-registry-cache .
```

## 运行
```
docker run -d --name docker-registry-cache -v ~/squid-cache:/var/cache/squid -v ~/ssr.json:/etc/shadowsocks/config.json -v ~/CA.pem:/etc/squid/ssl_cert/CA.pem -p 3128:3128 -p 80:80 docker-registry-cache
```
-v ~/squid-cache:/var/cache/squid            设置缓存目录  
-v ~/ssr.json:/etc/shadowsocks/config.json   过某防火墙用的配置，外边那位需要自己解决  
-v ~/CA.pem:/etc/squid/ssl_cert/CA.pem       证书，用于动态生成缓存HTTPS用的证书  

## 使用
1. 下载证书：curl -O 127.0.0.1/ca.cert
2. 信任/安装证书
3. http代理设置为http://127.0.0.1:3128，开始使用

## 特殊使用
- 终端使用
```
export http_proxy=http://127.0.0.1:3128
export https_proxy=http://127.0.0.1:3128
export no_proxy='127.0.0.0/8,10.0.0.0/8,172.17.0.0/16,192.168.64.0/24'
curl ip.gs
```
- 给minikube使用  
下载到的证书放在~\.minikube\files\etc\ssl\certs，然后minikube start

## 小声嘀咕
\u6d3b\u5728\u5929\u671d\u5c31\u5f97\u6bd4\u56fd\u5916\u7684\u5c0f\u670b\u53cb\u66f4\u52aa\u529b\uff0c\u6bd4\u5982\u642d\u68af\u5b50\u5b66\u4e60\u3002
