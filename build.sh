#!/bin/bash

docker build -t harbor.haodai.net/chenmin/docker-registry-cache:squid3 -f Dockerfile-squid3 .
docker push harbor.haodai.net/chenmin/docker-registry-cache:squid3
docker tag harbor.haodai.net/chenmin/docker-registry-cache:squid3 harbor.haodai.net/chenmin/docker-registry-cache:latest
docker push harbor.haodai.net/chenmin/docker-registry-cache:latest
#docker build -t harbor.haodai.net/chenmin/docker-registry-cache:squid4 -f Dockerfile-squid4 .
#docker push harbor.haodai.net/chenmin/docker-registry-cache:squid4
