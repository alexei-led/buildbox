#!/bin/bash

CFNET=${CFNET:-codefresh_net}
REG_VERSION="${REG_VERSION:=2.6}"

# stop previous instance
docker rm -f v2_mirror 2>/dev/null

# start Docker registry mirror
docker run -d --restart=always --name registry \
  --hostname "registry" \
  --network "${CFNET}" \
  -v "$PWD"/rdata:/var/lib/registry \
  -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
  registry:${REG_VERSION}