#!/bin/bash

set -e

DIND_VERSION="${DIND_VERSION:=1.13.1}"

print_usage() {
  USAGE="$(basename $0) [options] ... \n   
             options: -s|--sslcerts - CF SSL certificates location (default: etc/ssl/codefresh) \n
                      -n|--net - CF Docker network (default: codefresh_net) \n
                      -i|--id runtime id (numeric index) for buildbox container (default: 0) \n
                      -c|--cpuset-cpus - CPU cores to use, see Docker run reference (default: 0) \n
                      -r|--registry-mirror - Docker registry mirror (default: http://registry:5000) \n
                      -m|--memory - memory limit; it will be twice bigger: RAM + Swap (default: 2G))"
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
    -i|--id)
        ID="$value"
        shift
      ;;
    -c|--cpuset-cpus)
        CPU_CORES="$value"
        shift
      ;; 
    -r|--registry-mirror)
        REGISTRY_MIRROR="$value"
        shift
      ;; 
    -m|--memory)
        MEM_LIMIT="$value"
        shift
      ;; 
  esac
  shift # past argument or value
done

# Registry mirror
REGISTRY_MIRROR=${REGISTRY_MIRROR:-"http://registry:5000"}

# Codefresh certificates
CFCERTS_ROOT=${CFCERTS_ROOT:/etc/ssl/codefresh}
SRV_TLS_KEY=${CFCERTS_ROOT}/cf-server-key.pem
SRV_TLS_CERT=${SRV_TLS_KEY}/cf-server-cert.pem
SRV_TLS_CA_CERT=${CFCERTS_ROOT}/cf-ca.pem

# other
CFNET=${CFNET:-codefresh_net}
ID=${ID:-0}

# resource limitation
CPU_CORES=${CPU_CORES:-0}
MEM_LIMIT=${MEM_LIMIT:-2G}

# create docker ssl volume if needed
DOCKER_SSL_VOL=$(docker ps -aq --filter "name=docker-ssl-vol")
if [ -z "${DOCKER_SSL_VOL}" ]; then
  docker create -v /etc/docker/ssl --name docker-ssl-vol --entrypoint sh busybox
  docker cp "${SRV_TLS_KEY}" docker-ssl-vol:"${CFCERTS_ROOT}"
  docker cp "${SRV_TLS_CERT}" docker-ssl-vol:"${CFCERTS_ROOT}"
  docker cp "${SRV_TLS_CA_CERT}" docker-ssl-vol:"${CFCERTS_ROOT}"
fi

# create docker volume container for /var/lib/docker, if needed
DOCKER_VOL=$(docker ps -aq --filter "name=docker-lib-vol-${ID}")
if [ -z "${DOCKER_VOL}" ]; then
  docker create -v /var/lib/docker --name "docker-lib-vol-${ID}" busybox
fi

# run Docker dind image with overlay2 FS
docker run -d --privileged \
   --name "buildbox-${ID}" \
   --hostname "buildbox-dind-${ID}" \
   -e "ID=${ID}" \
   -p 2375${ID}:2375 \
   --net "${CFNET}" \
   --cpu-shares=512 \
   --cpuset-cpus="${CPU_CORES}" \
   --memory="${MEM_LIMIT}" \
   --volumes-from docker-ssl-vol \
   --volumes-from "docker-lib-vol-${ID}" \
   --restart=always \
   alexeiled/buildbox:${DIND_VERSION} \
     --tlsverify \
     --tlscacert="${SRV_TLS_CA_CERT}" \
     --tlscert="${SRV_TLS_CERT}"  \
     --tlskey="${SRV_TLS_KEY}" \
     --registry-mirror="${REGISTRY_MIRROR}" \
     --storage-driver overlay2 --storage-opt overlay2.override_kernel_check=1