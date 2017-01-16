#!/bin/bash

# replace _ID_ with
sed -i -e "s/\__ID__/${ID}/g" register.json

echo "Register Node"
curl -X PUT -d @register.json consul:8500/v1/catalog/register

echo "Create Node KV records"
./services-kv.sh -c consul -n buildbox-dind-${ID} -p codefresh.dev -a codefresh -t builder