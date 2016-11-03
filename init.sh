#!/bin/bash

set -e

for i in {1..2}; do

    buildbox_name=buildbox-node-${i}

    echo "Start buildbox ${i} dind worker"
    docker run -d --privileged \
        --name ${buildbox_name} \
        --hostname=buildbox-host-${i} \
        --cpu-shares 1024 \
        --shm-size=1g \
        -p ${i}2375:2375 \
        buildbox:1.12.1-dind --storage-driver=aufs

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
