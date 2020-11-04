SHELL := /bin/bash

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
	source get_env.sh && k3sup install \
		  --ip $$IP0 \
		  --user ubuntu \
		  --cluster \
		  --k3s-channel latest
	source get_env.sh && k3sup join \
	  --ip $$IP1 \
	  --user ubuntu \
	  --server-user ubuntu \
	  --server-ip $$IP0 \
	  --server \
	  --k3s-channel latest
	source get_env.sh && k3sup join \
	  --ip $$IP2 \
	  --user ubuntu \
	  --server-user ubuntu \
	  --server-ip $$IP0 \
	  --server \
	  --k3s-channel latest
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
