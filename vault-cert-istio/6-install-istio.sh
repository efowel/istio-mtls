#!/bin/sh
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=root
export VAULT_NAMESPACE=vault
int_ca=pki_int
name=safibank
common_name="safibank.online"
vauld_dns=http://vault.vault.svc.cluster.local:8200

#install operator
helm upgrade --install \
    istio-operator manifests/istio-operator \
    --namespace istio-operator \
    --create-namespace \
    --set watchedNamespaces="istio-system"

kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "mtls"
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
EOF

kubectl apply -f istiod-by-operator.yaml