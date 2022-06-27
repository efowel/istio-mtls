#!/bin/sh
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=root
export VAULT_NAMESPACE=vault
int_ca=pki_int
name=safibank
common_name="safibank.online"
vauld_dns=http://vault.vault.svc.cluster.local:8200

set -o xtrace
#Create PKI role
vault write $int_ca/roles/$name \
    allowed_domains="svc" \
    allowed_domains="$common_name" \
    allow_subdomains=true \
    max_ttl="720h" \
    require_cn=false \
    allowed_uri_sans="spiffe://cluster.local/*"

#create a new policy to create update revoke and list certificates
# path "pki_int/sign/safibank" {
#   capabilities = ["update"]
# }
vault policy write cert-manager - << EOF
path "$int_ca/sign/safibank" {capabilities = ["update"]}
EOF

#Create Vault AppRole
vault auth enable approle

#Create Vault role
vault write auth/approle/role/$name-istio \
    token_policies="cert-manager" \
    token_ttl=1h \
    token_max_ttl=4h

vault list auth/approle/role