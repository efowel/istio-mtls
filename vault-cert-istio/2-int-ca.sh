#!/bin/sh
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=root
export VAULT_NAMESPACE=vault
rootca=pki
name=pki_int
protocol=http
common_name="safibank.online"
vauld_dns=http://vault.vault.svc.cluster.local:8200

set -o xtrace
#enable pki secret engine for intermediate CA
vault secrets enable -path=$name pki

#set default ttl
vault secrets tune -max-lease-ttl=43800h $name

#create intermediate CA with common name example.com and 
#save the CSR (Certificate Signing Request) in a seperate file
vault write -format=json $name/intermediate/generate/internal \
        common_name="Safibank.online Intermediate Authority for Istio Testing" \
        | jq -r '.data.csr' > pki_intermediate.csr

#send the intermediate CA's CSR to the root CA for signing
#save the generated certificate in a sepearate file         
vault write -format=json $rootca/root/sign-intermediate csr=@pki_intermediate.csr \
        format=pem_bundle ttl="43800h" \
        | jq -r '.data.certificate' > intermediate.cert.pem


#publish the signed certificate back to the Intermediate CA
vault write $name/intermediate/set-signed certificate=@intermediate.cert.pem

#publish the intermediate CA urls
# vault write pki_int_test/config/urls \
#      issuing_certificates="http://vault.vault.svc.cluster.local:8200/v1/$name/ca" \
#      crl_distribution_points="http://vault.vault.svc.cluster.local:8200/v1/$name/crl"

vault write $name/config/urls \
        issuing_certificates="$vauld_dns/v1/$name/ca" \
        crl_distribution_points="$vauld_dns/v1/$name/crl"

#kube secrets for intermediate pem
kubectl  -n cert-manager create secret generic istio-root-ca --from-file=ca.cert.pem=intermediate.cert.pem