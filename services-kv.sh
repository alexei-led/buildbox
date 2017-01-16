#!/bin/bash
#
#
# Creates docker-node services kv entry 
# Usage: services-kv.sh -h|--help 
#        

print_usage() {
  USAGE="$(basename $0) [options] ... \n   
             options: -c|--consul - consul address:[port] \n
                      -n|--node-name \n
                      -p|--public-ip \n
                      -a|--account cf-account-name - (default = codefresh\n
                      -t|--rt-type rt-type (runner|builder , default = runner) \n"
  echo -e "USAGE:\n $USAGE"
}

if [[ "$#" -eq 0 || $1 =~ (-h|--help) ]]; then
  print_usage
  exit 0
fi

while [[ $1 =~ ^(-(c|n|p|a|t)|--(consul|node-name|public-ip|account|rt-type)) ]]
do
  key=$1
  value=$2

  case $key in
    -c|--consul)
        CONSUL="$value"
        shift
      ;;
    -n|--node-name)
        NODE_NAME="$value"
        shift
      ;;        
    -p|--public-ip)
        PUBLIC_IP="$value"
        shift
      ;;  
    -a|--account)
        ACCOUNT="$value"
        shift
      ;;
    -t|--rt-type)
        RT_TYPE="$value"
        shift
      ;; 
  esac
  shift # past argument or value
done

NODE_NAME=${NODE_NAME:-$(hostname)}
CONSUL=${CONSUL:-localhost}
PUBLIC_IP=${PUBLIC_IP:-codefresh.dev}
ACCOUNT=${ACCOUNT:-codefresh}
ROLE=${RT_TYPE:-runner}

cnt=0
while [[ $cnt -lt 20 ]]
do

   echo "INSERT KV BLOCK ..."                                                                        
   LEADER=$(curl -s $CONSUL:8500/v1/status/leader)                                             
   echo "Consul Leader = $LEADER "                                                                   
   if [[ $? != 0 || -z $LEADER || $LEADER == '""' ]]; then                                           
      echo "Waiting for consul ... " && sleep 3                                                      
      continue                                                                                       
   fi 
   
   CPU_CORES=$(cat /proc/cpuinfo | grep "^processor" | wc -l)
   CPU_MODEL=$(cat /proc/cpuinfo | awk -F ': ' '/model name/{print $2}' | head -n1)
   RAM="$(free -m | awk '/Mem:/{print $2}')M"
   SYSTEM_DISK=$(/bin/df -h /var/lib/docker | awk 'NR==2{print $2}')
   CREATION_DATE=$(date +"%Y-%m-%d %H:%M")
   OS_NAME=$(. /etc/os-release 2>/dev/null && echo ${PRETTY_NAME:-$ID} || echo linux)
   HOSTNAME=$(hostname)   
   SYSTEM_DATA="{\"cpu_cores\": \"$CPU_CORES\",
\"cpu_model\": \"$CPU_MODEL\",
\"ram\": \"$RAM\",
\"system_disk\": \"$SYSTEM_DISK\",
\"os_name\": \"$OS_NAME\",
\"hostname\": \"$HOSTNAME\",
\"creation_date\": \"$CREATION_DATE\"}"
   
   PROVIDER="{\"name\": \"local\", \"type\": \"internal\"}"
   
   
   curl -s -X PUT -d ${PUBLIC_IP} http://$CONSUL:8500/v1/kv/services/docker-node/${NODE_NAME}/publicAddress && \
   curl -s -X PUT -d ${ACCOUNT} http://$CONSUL:8500/v1/kv/services/docker-node/${NODE_NAME}/account && \
   curl -s -X PUT -d ${ROLE} http://$CONSUL:8500/v1/kv/services/docker-node/${NODE_NAME}/role && \
   curl -s -X PUT -d "${PROVIDER}" http://$CONSUL:8500/v1/kv/services/docker-node/${NODE_NAME}/systemData  && \
   curl -s -X PUT -d "${SYSTEM_DATA}" http://$CONSUL:8500/v1/kv/services/docker-node/${NODE_NAME}/provider
   if [[ $? != 0 ]]; then
     echo "Waiting for consul KV ... " && sleep 3 
     continue
   fi   
   break
done
