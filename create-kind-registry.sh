#!/bin/bash
set -o errexit

REG_NAME='kind-registry'
REG_PORT='5001'
DOCKER_REGISTRY=localhost:${REG_PORT}
DOCKER_TAG=force-awakens

IMAGES=( \
'cilium:v1.14.0-snapshot.2@sha256:fb92067c1c5c031ae6a6581ef46c35304acb316850d718470fef58c5571f150b' \
'clustermesh-apiserver:1.14.0-snapshot.2@sha256:9e06603b72be5eff51930af3cbdd945d0b69f514531ba1569bb4a4b26fad2521' \
'operator:v1.14.0-snapshot.2@sha256:16acb7bb9145dd998a046f3c46fc6ccd3585ae8de2a21f814a1e69bf8bf82874' \
'hubble-relay:v1.14.0-snapshot.2@sha256:d7bca0ec8e6b0597b11d8ddca4e889fdab0057a0e7dcf4ea8e1faae69c20d5de' \
'operator-generic:v1.14.0-snapshot.2@sha256:ac6e3f6058c2692decba6d8b84f8b505b5b677ead8efc78c1ca234873fb92b63' \
)

# create registry container unless it already exists
if [ "$(docker inspect -f '{{.State.Running}}' "${REG_NAME}" 2>/dev/null || true)" != 'true' ]; then
  docker run \
    -d --restart=always -p "${REG_PORT}:5000" --name "${REG_NAME}" \
    registry:2
fi

# Build and upload netcat-message to it
docker build netcat-message -t ${DOCKER_REGISTRY}/netcat-message:${DOCKER_TAG}
docker push ${DOCKER_REGISTRY}/netcat-message:${DOCKER_TAG}

# Download and upload to local registry the cilium images
for image in "${IMAGES[@]}"; do
    parts=(${image//:/ })
    docker pull quay.io/cilium/${image}
    docker tag quay.io/cilium/${image} ${DOCKER_REGISTRY}/cilium/${parts[0]}:${DOCKER_TAG}
    docker push ${DOCKER_REGISTRY}/cilium/${parts[0]}:${DOCKER_TAG}
done

# Also include etcd in the local registry, needed for deploying clustermesh
docker pull quay.io/coreos/etcd:v3.5.4
docker tag quay.io/coreos/etcd:v3.5.4 ${DOCKER_REGISTRY}/coreos/etcd:v3.5.4
docker push ${DOCKER_REGISTRY}/coreos/etcd:v3.5.4

