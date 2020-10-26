#!/usr/bin/env bash

NODE_ID=$1
CMD="${@:2}"

source get_env.sh

var="IP${NODE_ID}"
NODE_IP=${!var}

ssh ubuntu@"${NODE_IP}" ${CMD}
