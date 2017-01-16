#!/bin/bash

print_usage() {
  USAGE="$(basename $0) [options] ... \n   
             options: -s|--sslcerts - CF SSL certificates location (default: ~/.docker/cfcerts) \n
                      -n|--net - CF Docker network (default: codefresh_default) \n
                      -r|--registry - local registry IP or IP range (default: 192.168.99.1/24) \n
                      -i|--id runtime id (numeric index) for buildbox container (default: 1) \n
                      -c|--cpuset-cpus - CPU cores to use, see Docker run reference (default: 0-1) \n
                      -m|--memory - memory limit; it will be twice bigger: RAM + Swap (default: 1G))"
  echo -e "USAGE:\n $USAGE"
}

if [[ $1 =~ (-h|--help) ]]; then
  print_usage
  exit 0
fi

while [[ $1 =~ ^(-(s|n|r|i|c|m)|--(sslcerts|net|registry|id|cpuset-cpus|memory)) ]]
do
  key=$1
  value=$2

  case $key in
    -s|--sslcerts)
        CFCERTS_ROOT="$value"
        shift
      ;;
    -n|--net)
        CFNET="$value"
        shift
      ;;        
    -r|--registry)
        CF_REGISTRY="$value"
        shift
      ;;  
    -i|--id)
        ID="$value"
        shift
      ;;
    -c|--cpuset-cpus)
        CPU_CORES="$value"
        shift
      ;; 
    -m|--memory)
        MEM_LIMIT="$value"
        shift
      ;; 
  esac
  shift # past argument or value
done

CFCERTS_ROOT=${CFCERTS_ROOT:-~/.docker/cfcerts}
CFNET=${CFNET:-codefresh_default}
CF_REGISTRY=${CF_REGISTRY:-192.168.99.1/24}
ID=${ID:-1}
# resource limitation
CPU_CORES=${CPU_CORES:-0-1}
MEM_LIMIT=${MEM_LIMIT:-1G}

# create docker ssl volume if needed
DOCKER_SSL_VOL=$(docker ps -aq --filter "name=docker-ssl-vol")
if [ -z "${DOCKER_SSL_VOL}" ]; then
  docker create -v /etc/docker/ssl --name docker-ssl-vol --entrypoint sh busybox
  docker cp ${CFCERTS_ROOT}/ca-key.pem docker-ssl-vol:/etc/docker/ssl/
  docker cp ${CFCERTS_ROOT}/ca.pem docker-ssl-vol:/etc/docker/ssl/
  docker cp ${CFCERTS_ROOT}/server.pem docker-ssl-vol:/etc/docker/ssl/
  docker cp ${CFCERTS_ROOT}/server-key.pem docker-ssl-vol:/etc/docker/ssl/
fi

# create docker volume container for /var/lib/docker, if needed
DOCKER_VOL=$(docker ps -aq --filter "name=docker-lib-vol-${ID}")
if [ -z "${DOCKER_VOL}" ]; then
  docker create -v /var/lib/docker --name docker-lib-vol-${ID} busybox
fi

# run Docker dind image 
docker run -d --privileged \
   --name buildbox-${ID} \
   --hostname=buildbox-dind-${ID} \
   --shm-size=1g \
   -e "ID=${ID}" \
   -p 2375${ID}:2375 \
   --net=${CFNET} \
   --cpu-shares=512 \
   --cpuset-cpus="${CPU_CORES}" \
   --memory="${MEM_LIMIT}" \
   --volumes-from docker-ssl-vol \
   --volumes-from docker-lib-vol-${ID} \
   alexeiled/buildbox:1.12.6-dind \
     --tlsverify --tlscacert=/etc/docker/ssl/ca.pem \
     --tlscert=/etc/docker/ssl/server.pem \
     --tlskey=/etc/docker/ssl/server-key.pem \
     --insecure-registry ${CF_REGISTRY} \
     -s overlay2 --storage-opt overlay2.override_kernel_check=1 \
     --userns-remap=default