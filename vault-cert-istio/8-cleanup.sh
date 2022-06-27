helm -n cert-manager delete cert-manager-istio-csr

helm -n cert-manager delete cert-manager

helm -n vault delete vault

helm -n istio-operator delete operator

kubectl -n foo delete -f sample

kubectl delete ns cert-manager vault istio-system istio-operator foo

rm -f ca.pem intermediate.cert.pem