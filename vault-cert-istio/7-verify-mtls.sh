#!/bin/sh
kubectl create ns foo
kubectl label ns foo istio-injection=enabled
kubectl -n foo apply -f sample/sleep.yaml

id=$(kubectl -n foo get po | grep sleep | awk '{print$1}')

set -o xtrace
sleep 15s
getmesh istioctl pc secret $id.foo -o json