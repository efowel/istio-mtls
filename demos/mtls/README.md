#  Authentication - Istio Mutual TLS v1.14.1

By default, Istio configures client proxies to send mutual TLS traffic to those workloads automatically, and to send plain text traffic to workloads without sidecars. (PERMISSIVE)

> source: https://istio.io/latest/docs/tasks/security/authentication/authn-policy/


## Authentication | Deploy Pods w/o sidecar

Create Namespace foo, bar and legacy

```
for x in "foo" "bar" "legacy"; do kubectl create ns $x; done

kubectl get ns
```

Deploy [httpbin](sample/httpbin.yaml) and [sleep](sample/sleep.yaml) pod to namesapce with no sidecars. 

```
for x in "foo" "bar" "legacy"; do kubectl apply -f sample/ -n $x; done

for x in "foo" "bar" "legacy"; do kubectl get po -n $x; done
```

Test communication between pods and namespaces

```
for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done

```
## Authentication | Deploy Pods with sidecar


Deploy sidecar with namespace label istio-injection=disabled `(foo namespace)`

```
#label the namespace
kubectl label namespace foo istio-injection=enabled --overwrite && kubectl -n foo get po

#delete and watch pods
kubectl -n foo delete po -l app=httpbin && kubectl -n foo get po -w

kubectl -n foo delete po -l app=sleep && kubectl -n foo get po -w

#check pods
for x in "foo" "bar" "legacy"; do kubectl get po -n $x; done
```
Deploy sidecar using istioctl injection `(bar namespace)`

```
kubectl apply -f <(istioctl kube-inject -f sample/httpbin.yaml) -n bar && kubectl -n bar get po -w

kubectl -n bar get po

kubectl apply -f <(istioctl kube-inject -f sample/sleep.yaml) -n bar && kubectl -n bar get po -w

#check pods
for x in "foo" "bar" "legacy"; do kubectl get po -n $x; done
```

Test communication between pods and namespaces

```
for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
```
### Verify mtls
When using mutual TLS, the proxy injects the `X-Forwarded-Client-Cert` header to the upstream request to the backend. That header’s presence is evidence that mutual TLS is used.

```
#check header

kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl -s http://httpbin.foo:8000/headers -s | grep X-Forwarded-Client-Cert | sed 's/Hash=[a-z0-9]*;/Hash=<redacted>;/'
```

```
#check header from foo to legacy

kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.legacy:8000/headers -s | grep X-Forwarded-Client-Cert

```

### Enforce mutual tls to a namespace
Apply `PeerAuthentication` to namespace foo <br/> 
Scope:
* Mesh wide
* Namespace
* Wokrload/Pod (used with selector match)
* Port
```
########
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "foo-mtls"
  namespace: "foo"
spec:
  mtls:
    mode: STRICT
        #- PERMISSIVE
        #- DISABLE
        #- UNSET
########

kubectl apply -f foo-mtls.yaml
```
Test communication between pods and namespaces

```
for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
```
Cleanup
```
for x in "foo" "bar" "legacy"; do kubectl delete -f sample/ -n $x; done
```

## Authentication | RequestAuthentication

RequestAuthentication defines what request authentication methods are supported by a workload. It will reject a request if the request contains invalid authentication information, based on the configured authentication rules <br/>

Setup
```
kubectl apply -f <(istioctl kube-inject -f sample/sleep.yaml) -n foo

kubectl apply -f <(istioctl kube-inject -f sample/sleep.yaml) -n foo

kubectl apply -f gateway.yaml

#test
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')

curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
```

Deploy [RequestAuthentication](requestauthentication.yaml) to namesapce with no sidecars.

```
kubectl apply -f requestauthentication.yaml
```
> https://raw.githubusercontent.com/istio/istio/release-1.14/security/tools/jwt/samples/jwks.json




#  Authorization - Istio Mutual TLS v1.14.1