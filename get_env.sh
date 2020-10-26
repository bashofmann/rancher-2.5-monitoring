#!/usr/bin/env bash

$(terraform output -state=terraform-setup/terraform.tfstate -json all_node_ips | jq -r 'keys[] as $k | "export IP\($k)=\(.[$k])"')
