#!/bin/bash

docker build -t klutzchenmin/docker-registry-cache:squid3 -f Dockerfile-squid3 .
docker push klutzchenmin/docker-registry-cache:squid3
docker build -t klutzchenmin/docker-registry-cache:squid4 -f Dockerfile-squid4 .
docker push klutzchenmin/docker-registry-cache:squid4

docker tag klutzchenmin/docker-registry-cache:squid3 klutzchenmin/docker-registry-cache:latest
docker push klutzchenmin/docker-registry-cache:latest
