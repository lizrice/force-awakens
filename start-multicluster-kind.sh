#!/bin/sh
set -eux

CILIUM_DIR=~/src/cilium

REG_NAME='kind-registry'
REG_PORT='5001'
CHART_DIR="${CILIUM_DIR}/install/kubernetes/cilium"

# This values are used inside the values.yaml files and need to be exported
export DOCKER_REGISTRY=localhost:${REG_PORT}
export DOCKER_TAG=force-awakens

# Create the directories for the clusters and add the .envrc for this to work with direnv
for cluster in jakku d-qar; do
    mkdir -p $cluster
    echo "export KUBECONFIG=./kubeconfig" > $cluster/.envrc
done

JAKKU_KUBECONFIG=jakku/kubeconfig
DQAR_KUBECONFIG=d-qar/kubeconfig
export KUBECONFIG=${JAKKU_KUBECONFIG}:${DQAR_KUBECONFIG}

# Create the Jakku cluster
kind create cluster --config cluster-jakku.yaml --kubeconfig ${JAKKU_KUBECONFIG}

docker network connect "kind" ${REG_NAME}
cat values-cluster-jakku.yaml | envsubst | cilium install --helm-values /dev/stdin --wait --chart-directory "${CHART_DIR}" --cluster-name jakku 
cilium clustermesh enable --service-type NodePort --apiserver-image ${DOCKER_REGISTRY}/cilium/clustermesh-apiserver:${DOCKER_TAG}
cilium clustermesh status --wait

# Create the D'Qar cluster
kind create cluster --config cluster-d-qar.yaml --kubeconfig ${DQAR_KUBECONFIG}

cat values-cluster-d-qar.yaml | envsubst | cilium install --helm-values /dev/stdin --wait --chart-directory "${CHART_DIR}" --inherit-ca kind-jakku --cluster-name d-qar --context kind-d-qar
cilium clustermesh enable --service-type NodePort --apiserver-image $DOCKER_REGISTRY/cilium/clustermesh-apiserver:$DOCKER_TAG --context kind-d-qar
cilium clustermesh status --wait --context kind-d-qar
cilium clustermesh connect --context kind-jakku --destination-context kind-d-qar

# Generate YAML files with the variables replaced
cat bb-8.spec.yaml | envsubst > jakku/bb-8.yaml
cat resistance-jakku.spec.yaml | envsubst > jakku/resistance-jakku.yaml
cat resistance-d-qar.spec.yaml | envsubst > d-qar/resistance-d-qar.yaml
cat kylo-ren.spec.yaml | envsubst > d-qar/kylo-ren.yaml
cat r2-d2.spec.yaml | envsubst > d-qar/r2-d2.yaml

# Copy the files needed for the demo to the directories for each cluster
cp luke.yaml d-qar/
cp protect.yaml jakku/
cp protect.yaml d-qar/
