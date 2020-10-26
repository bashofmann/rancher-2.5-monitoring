SHELL := /bin/bash

K3S_TOKEN="VA87qPxet2SB8BDuLPWfU2xnPUSoETYF"

export KUBECONFIG=kubeconfig

destroy:
	cd terraform-setup && terraform destroy -auto-approve && rm terraform.tfstate terraform.tfstate.backup

install: step_01 step_02 step_03

step_01:
	echo "Creating infrastructure"
	cd terraform-setup && terraform init && terraform apply -auto-approve
	sleep 30

step_02:
	echo "Creating k3s cluster on ubuntu vms 0,1,2"
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP0} "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=v1.19 INSTALL_K3S_EXEC='server' K3S_TOKEN=$(K3S_TOKEN) K3S_KUBECONFIG_MODE=644 K3S_CLUSTER_INIT=1 sh -"
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP1} "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=v1.19 INSTALL_K3S_EXEC='server' K3S_TOKEN=$(K3S_TOKEN) K3S_URL=https://$${IP0}:6443 sh - "
	source get_env.sh && ssh -o StrictHostKeyChecking=no ubuntu@$${IP2} "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=v1.19 INSTALL_K3S_EXEC='server' K3S_TOKEN=$(K3S_TOKEN) K3S_URL=https://$${IP0}:6443 sh - "
	source get_env.sh && scp -o StrictHostKeyChecking=no ubuntu@$${IP0}:/etc/rancher/k3s/k3s.yaml kubeconfig
	source get_env.sh && sed -i "s/127.0.0.1/$${IP0}/g" kubeconfig
	sleep 20

step_03:
	echo "Installing cert-manager and Rancher"
	helm repo update
	helm upgrade --install \
		  cert-manager jetstack/cert-manager \
		  --namespace cert-manager \
		  --version v1.0.3 --create-namespace --set installCRDs=true
	kubectl rollout status deployment -n cert-manager cert-manager
	kubectl rollout status deployment -n cert-manager cert-manager-webhook
	helm upgrade --install rancher rancher-latest/rancher \
	  --namespace cattle-system \
	  --version 2.5.1 \
	  --set hostname=rancher-demo.plgrnd.be --create-namespace
	kubectl rollout status deployment -n cattle-system rancher
	kubectl -n cattle-system wait --for=condition=ready certificate/tls-rancher-ingress
