#!/bin/sh
set -eu

kind create cluster --config cluster-jakku.yaml

docker network connect "kind" kind-registry

cat values-cluster-jakku.yaml | envsubst | cilium install --helm-values /dev/stdin --wait --chart-directory $CHART_DIR --cluster-name jakku 
cilium clustermesh enable --service-type NodePort --apiserver-image $DOCKER_REGISTRY/cilium/clustermesh-apiserver:$DOCKER_TAG
cilium clustermesh status --wait

kind create cluster --config cluster-d-qar.yaml

cat values-cluster-d-qar.yaml | envsubst | cilium install --helm-values /dev/stdin --wait --chart-directory $CHART_DIR --inherit-ca kind-jakku --cluster-name d-qar
cilium clustermesh enable --service-type NodePort --apiserver-image $DOCKER_REGISTRY/cilium/clustermesh-apiserver:$DOCKER_TAG
cilium clustermesh status --wait
cilium clustermesh connect --context kind-jakku --destination-context kind-d-qar