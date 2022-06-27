#!/bin/sh
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=root
export VAULT_NAMESPACE=vault
name=pki
protocol=http
common_name="safibank.online"
vauld_dns=http://vault.vault.svc.cluster.local:8200

set -o xtrace

#enable Vault PKI secret engine 
vault login root

vault secrets enable -path=$name pki

#set default ttl
vault secrets tune -max-lease-ttl=87600h $name

#generate root CA
vault write -field=certificate $name/root/generate/internal \
common_name="$common_name" ttl=8760h  > ca.pem

#publish urls for the root ca
vault write $name/config/urls \
        issuing_certificates="$vauld_dns/v1/$name/ca" \
        crl_distribution_points="$vauld_dns/v1/$name/crl"
