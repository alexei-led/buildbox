#!/bin/bash

set -e

[ -z "$NUM_BOXES" ] && NUM_BOXES=3
[ -z "$DIND_VERSION" ] && DIND_VERSION="1.12.5"

# start Docker registry mirror
docker run -d --restart=always -p 5000:5000 --name v2_mirror \
  -v $PWD/rdata:/var/lib/registry \
  -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
  registry:2.5

# get Docker host IP
DOCKER_HOST_IP=$(docker info --format "{{.Swarm.NodeAddr}}")

# start NUM_BOXES og buildbox instances 
# connect SSH container to every instance
# ignore (bug): mount `/var/lib/docker` to `./cdata/box-{instance}` folder
for i in $(seq "${NUM_BOXES}"); do

    buildbox_name=buildbox-node-${i}

    echo "Start buildbox ${i} dind worker"
    docker run -d --privileged \
        --name ${buildbox_name} \
        --hostname=buildbox-host-${i} \
        --cpu-shares 1024 \
        --shm-size=1g \
        -p ${i}2375:2375 \
        alexeiled/buildbox:${DIND_VERSION}-dind \
          --registry-mirror http://${DOCKER_HOST_IP}:5000 \
          -s overlay2 --storage-opt overlay2.override_kernel_check=1

    echo "Start SSH container and connect to buildbox ${i}"
    docker run -d \
    -e CONTAINER=${buildbox_name} -e AUTH_MECHANISM=noAuth \
    --name sshd-${buildbox_name} \
    -p ${i}0022:22 \
    -p ${i}8022:8022 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    jeroenpeeters/docker-ssh:1.4.0

    echo "Select any option to connect to the buildbox container:"
    echo "   1. terminal:     ssh localhost -p ${i}0022"
    echo "   2. docker:       docker --host localhost:${i}2375"
    echo "   3. web terminal: open http://localhost:${i}8022"

done
