#!/bin/bash
set -eux

# On Linux, running three clusters needs these ctls increased:
sudo sysctl fs.inotify.max_user_instances=1280
sudo sysctl fs.inotify.max_user_watches=655360

# First, start the other two clusters and get all env variables
source ./start-multicluster-kind.sh

# Create the additional dir and .envrc for this to work with direnv
for cluster in ahch-to; do
    mkdir -p $cluster
    echo "export KUBECONFIG=./kubeconfig" > $cluster/.envrc
done

AHCHTO_KUBECONFIG=ahch-to/kubeconfig
export KUBECONFIG=${JAKKU_KUBECONFIG}:${DQAR_KUBECONFIG}:${AHCHTO_KUBECONFIG}

# Create Ahch-to cluster
kind create cluster --config cluster-ahch-to.yaml --kubeconfig ${AHCHTO_KUBECONFIG}
cat values-cluster-ahch-to.yaml | envsubst | cilium install --helm-values /dev/stdin --wait --chart-directory "${CHART_DIR}" --inherit-ca kind-jakku --cluster-name ahch-to --context kind-ahch-to
cilium clustermesh enable --service-type NodePort --apiserver-image $DOCKER_REGISTRY/cilium/clustermesh-apiserver:$DOCKER_TAG --context kind-ahch-to
cilium clustermesh status --wait --context kind-ahch-to
cilium clustermesh connect --context kind-jakku --destination-context kind-ahch-to
cilium clustermesh connect --context kind-d-qar --destination-context kind-ahch-to

# Generate and copy the necessary YAML files
cat jedi.spec.yaml | envsubst > ahch-to/jedi.yaml
cp luke.yaml ahch-to/
cp protect.yaml ahch-to/
