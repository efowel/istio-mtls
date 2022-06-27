#!/bin/sh
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=root
export VAULT_NAMESPACE=vault
int_ca=pki_int
name=safibank
common_name="safibank.online"
vauld_dns=http://vault.vault.svc.cluster.local:8200

kubectl -n cert-manager get secret istio-root-ca || exit 1

#install istio-csr
helm upgrade --install -n cert-manager \
    cert-manager-istio-csr jetstack/cert-manager-istio-csr \
    --set "app.certmanager.issuer.name=vault-issuer" \
    --set "app.tls.rootCAFile=/var/run/secrets/istio-csr/ca.cert.pem" \
    --set "volumeMounts[0].name=root-ca" \
    --set "volumeMounts[0].mountPath=/var/run/secrets/istio-csr" \
    --set "volumes[0].name=root-ca" \
    --set "volumes[0].secret.secretName=istio-root-ca"

sleep 10s
kubectl -n cert-manager get pods