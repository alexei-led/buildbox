#!/bin/bash

CFNET=${CFNET:-codefresh_net}

docker network create --attachable=true --subnet=192.170.0.0/16 "${CFNET}"