#!/bin/sh
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=root
export VAULT_NAMESPACE=vault
int_ca=pki_int
name=safibank
common_name="safibank.online"
vauld_dns=http://vault.vault.svc.cluster.local:8200

#grap role and secret value
role_id=$(vault read auth/approle/role/$name-istio/role-id -format=json | jq -r '.data.role_id')
secret_id=$(vault write -force auth/approle/role/$name-istio/secret-id -format=json | jq -r '.data.secret_id' |base64)

echo "role-id: $role_id"
echo "secret-id: $secret_id"

kubectl create ns istio-system

#Firstly, the ‘secretId’ must be stored inside a Kubernetes Secret on the same namespace as the Issuer.
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: cert-manager-vault-approle
  namespace: istio-system
data:
  secretId: $secret_id # insert secretId base64 encoded
EOF

#Create Issuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: vault-issuer
  namespace: istio-system
spec:
  vault:
    path: $int_ca/sign/$name
    server: $vauld_dns # for-variable
    auth:
      appRole:
        path: approle
        roleId: $role_id
        secretRef:
          name: cert-manager-vault-approle # for-variable
          key: secretId
EOF

kubectl get issuers vault-issuer -n istio-system -o wide