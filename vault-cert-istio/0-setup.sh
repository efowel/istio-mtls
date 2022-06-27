#!/bin/sh
set -o xtrace
helm repo add jetstack https://charts.jetstack.io
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

#install cert-manager
helm upgrade --install \
    cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version v1.8.0 \
    --set installCRDs=true


#install vault
helm upgrade --install \
    vault hashicorp/vault \
    --namespace vault \
    --create-namespace \
    --set "server.dev.enabled=true" \
    --set "server.dev.devRootToken=root"

#kubectl -n vault port-forward svc/vault 8200:8200