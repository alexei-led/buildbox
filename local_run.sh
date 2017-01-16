#!/bin/bash

NET=${NET:-codefresh_default}
ID=${ID:-1}

# create docker ssl volume if needed
DOCKER_SSL_VOL=$(docker ps -aq --filter "name=docker-ssl-vol")
if [ -z "${DOCKER_SSL_VOL}" ]; then
  docker create -v /etc/docker/ssl --name docker-ssl-vol --entrypoint sh busybox
  docker cp ${HOME}/.docker/cfcerts/ca-key.pem docker-ssl-vol:/etc/docker/ssl/
  docker cp ${HOME}/.docker/cfcerts/ca.pem docker-ssl-vol:/etc/docker/ssl/
  docker cp ${HOME}/.docker/cfcerts/server.pem docker-ssl-vol:/etc/docker/ssl/
  docker cp ${HOME}/.docker/cfcerts/server-key.pem docker-ssl-vol:/etc/docker/ssl/
fi

# create docker volume container for /var/lib/docker, if needed
DOCKER_VOL=$(docker ps -aq --filter "name=docker-lib-vol-${ID}")
if [ -z "${DOCKER_VOL}" ]; then
  docker create -v /var/lib/docker --name docker-lib-vol-${ID} busybox
fi

# run Dind image 
docker run -d --privileged \
   --name buildbox-${ID} \
   --hostname=buildbox-dind-${ID} \
   --shm-size=1g \
   -e "ID=${ID}" \
   -p 2375${ID}:2375 \
   --net=${NET} \
   --volumes-from docker-ssl-vol \
   --volumes-from docker-lib-vol-${ID} \
   alexeiled/buildbox:1.12.5-dind \
     --tlsverify --tlscacert=/etc/docker/ssl/ca.pem \
     --tlscert=/etc/docker/ssl/server.pem \
     --tlskey=/etc/docker/ssl/server-key.pem \
     --insecure-registry 192.168.99.1/24 \
     -s overlay2 --storage-opt overlay2.override_kernel_check=1