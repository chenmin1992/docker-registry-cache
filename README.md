# docker-registry-cache
docker registry/images cache proxy, with bypass the certain firewall.  
docker registry/images 缓存，把docker镜像缓存起来下次就不用再费劲的拉了，可以翻越某防火墙。  
## 功能
- 缓存 docker pull 的镜像
- 使用任意代理, 进而可以翻越某大型防火墙, 从官方 registry 拉取 K8S 镜像
- 自定义CA
- 放行自定义域名

## 构建镜像
```bash
docker build -t klutzchenmin/docker-registry-cache .
```

## 假设
本机 IP 10.1.1.1

## 运行
```bash
docker run -d --name docker-registry-cache --restart always \
	-e PROXY=http://10.1.1.1:1080 -p 3128:3128 -p 80:80 \
	-v /data/docker-registry-cache/cache:/var/cache/squid \
	-v /data/docker-registry-cache/cert:/etc/squid/ssl_cert \
	klutzchenmin/docker-registry-cache
```
|选项|说明|
|:-|:-|
|-e PROXY=http://10.1.1.1:1080|设置使用外部代理|
|-p 3128:3128|代理端口|
|-p 80:80|下载证书端口|
|-v /data/docker-registry-cache/cache:/var/cache/squid|设置缓存持久化目录|
|-v /data/docker-registry-cache/cert:/etc/squid/ssl_cert|证书, 用于动态生成缓存HTTPS用的证书, 不设置可以自动生成|

## 使用
1. 下载证书: http://127.0.0.1/ca.crt
2. 信任/安装证书
3. http代理设置为 http://127.0.0.1:3128 ，开始使用

## 特殊使用
- 终端使用
```bash
export http_proxy='http://127.0.0.1:3128'
export https_proxy='http://127.0.0.1:3128'
export no_proxy='localhost,127.0.0.0/8,10.0.0.0/8,172.17.0.0/16,172.31.0.0/16,192.168.0.0/16'
curl ip.gs
```
- 给minikube使用  
下载到的证书放在 ~/.minikube/files/etc/ssl/certs , 然后
```bash
minikube start --docker-env HTTP_PROXY=http://10.1.1.1:3128 --docker-env HTTPS_PROXY=http://10.1.1.1:3128 \
--docker-env NO_PROXY='localhost,127.0.0.0/8,10.0.0.0/8,172.17.0.0/16,172.31.0.0/16,192.168.0.0/16'
```
- 给docker使用
```bash
curl 127.0.0.1/ca.crt >> /etc/pki/ca-trust/source/anchors/ca.crt
update-ca-trust
cat > /etc/systemd/system/docker.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=http://172.17.49.101:3128"
Environment="HTTPS_PROXY=http://172.17.49.101:3128"
Environment="NO_PROXY=localhost,127.0.0.0/8,10.0.0.0/8,172.17.0.0/16,172.31.0.0/16,192.168.0.0/16"
EOF
systemctl restart docker
```

## 小声嘀咕
\u6d3b\u5728\u5929\u671d\u5c31\u5f97\u6bd4\u56fd\u5916\u7684\u5c0f\u670b\u53cb\u66f4\u52aa\u529b\uff0c\u6bd4\u5982\u642d\u68af\u5b50\u5b66\u4e60\u3002
