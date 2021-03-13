#!/bin/bash

cd ~/

# Task 1
export CLUSTER_NAME=central
export CLUSTER_ZONE=us-central1-b

export GCLOUD_PROJECT=$(gcloud config get-value project)

gcloud container clusters get-credentials $CLUSTER_NAME \
    --zone $CLUSTER_ZONE --project $GCLOUD_PROJECT

export LAB_DIR=$HOME/security-lab
export ISTIO_VERSION=1.5.2

mkdir $LAB_DIR
cd $LAB_DIR

curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$ISTIO_VERSION sh -

cd ./istio-*

export PATH=$PWD/bin:$PATH

cd $LAB_DIR

git clone https://github.com/GoogleCloudPlatform/istio-samples.git

cd istio-samples/security-intro

mkdir ./hipstershop

curl -o ./hipstershop/kubernetes-manifests.yaml https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml

istioctl kube-inject -f hipstershop/kubernetes-manifests.yaml -o ./hipstershop/kubernetes-manifests-withistio.yaml

kubectl apply -f ./hipstershop/kubernetes-manifests-withistio.yaml

# Task 2
curl -o ./hipstershop/istio-manifests.yaml https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/istio-manifests.yaml

kubectl apply -f hipstershop/istio-manifests.yaml

# Task 3
# kubectl -n istio-system port-forward \
#     $(kubectl -n istio-system get pod -l app=kiali -o jsonpath='{.items[0].metadata.name}') 8080:20001

export LAB_DIR=$HOME/security-lab
cd $LAB_DIR/istio-samples/security-intro

kubectl apply -f ./manifests/mtls-frontend.yaml

# Task 4

kubectl exec $(kubectl get pod -l app=productcatalogservice -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl http://frontend:80/ -o /dev/null -s -w '%{http_code}\n'

kubectl exec $(kubectl get pod -l app=productcatalogservice -o jsonpath={.items..metadata.name}) -c istio-proxy \
-- curl https://frontend:80/ -o /dev/null -s -w '%{http_code}\n'  --key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k

kubectl apply -f ./manifests/mtls-default-ns.yaml

# Task 5

kubectl apply -f ./manifests/authz-frontend.yaml

kubectl apply -f ./manifests/jwt-frontend-request.yaml

TOKEN=helloworld; echo $TOKEN

kubectl exec $(kubectl get pod -l app=productcatalogservice -o jsonpath={.items..metadata.name}) -c istio-proxy \
-- curl  http://frontend:80/ -o /dev/null --header "Authorization: Bearer $TOKEN" -s -w '%{http_code}\n'

kubectl exec $(kubectl get pod -l app=productcatalogservice -o jsonpath={.items..metadata.name}) -c istio-proxy \
-- curl  https://frontend:80/ -o /dev/null -s -w '%{http_code}\n' \
--key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k

kubectl apply -f manifests/jwt-frontend-authz.yaml

kubectl exec $(kubectl get pod -l app=productcatalogservice -o jsonpath={.items..metadata.name}) -c istio-proxy \
-- curl  https://frontend:80/ -o /dev/null -s -w '%{http_code}\n' \
--key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k

TOKEN=$(curl -k https://raw.githubusercontent.com/istio/istio/release-1.4/security/tools/jwt/samples/demo.jwt -s); echo $TOKEN

kubectl exec $(kubectl get pod -l app=productcatalogservice -o jsonpath={.items..metadata.name}) -c istio-proxy \
-- curl --header "Authorization: Bearer $TOKEN" https://frontend:80/ -o /dev/null -s -w '%{http_code}\n' \
--key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k

kubectl delete -f manifests/jwt-frontend-authz.yaml
kubectl delete -f manifests/jwt-frontend-request.yaml



