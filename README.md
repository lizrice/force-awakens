# Force Awakens Cilium Mesh demo

From KubeCon Amsterdam. Putting it here for now because some of what I showed
was in a feature branch.

TODO:
[ ] Build from feature branch for external workload feature
[ ] Re-test external workloads

## Prerequisites

* Docker
* Kind
* direnv
* Cilium CLI

`export CILIUM_DIR=<local Cilium repo>` (defaults to ~/src/cilium)
## Local registry for Kind clusters

Run `create-kind-registry.sh`. This runs a local registry, similar to
[this](https://kind.sigs.k8s.io/docs/user/local-registry/), and populates it
with the images needed for this demo. I run the local registry on port 5001
because 5000 was already in use on my Mac.

## Create universe

```
./start-multicluster-kind.sh
```

## Initial deploy

The first time you `cd` into a directory you'll need to run `direnv allow`.

```
cd jakku
k apply -f bb-8.yaml
k apply -f resistance-jakku.yaml

cd d-qar
k apply -f r2-d2.yaml
k apply -f kylo-ren.yaml
k apply -f resistance-d-qar.yaml
```

## Deploy Luke running in an external VM

Separate terminal:

```
docker run -d --network=kind --ip 172.19.100.2 --name ahch-to --rm -p 80:80 lizrice/ubuntu-ahch-to sleep 10000
docker exec -it ahch-to bash

# In VM
while true; do echo -e "HTTP/1.1 200 OK\n\nHi I'm Luke" | nc -l -p 80 -N ; done
```

## Accessing services and endpoints

In Jakku, bb-8 can access resistance

```
cd ../jakku
k exec -it bb-8 -- curl resistance
```

Look at services and endpoints

```
k get svc
k get pods -o wide
k get endpoints
k get ciliumendpoints

ks exec -it $CPOD -- cilium service list
ks exec -it $CPOD -- cilium endpoint list
```

## Clustermesh

Uncomment annotations in Jakku's resistance service to make it a global service,
so bb-8 can access resistance in both locations. Then `k apply -f resistance-jakku.yaml`

```
k get endpoints
k get ciliumendpoints
k get svc
ks exec -it $CPOD -- cilium service list
```

Resistance service in D'Qar is annotated to prefer local, so curling from R2-D2 should only
return responses from the local resistance in D'Qar.

## Luke is an external endpoint

```
cilium endpoint add --name=ahch-to --labels=org=resistance --labels=jedi=luke --ip=172.19.100.2
```

```
kubectx kind-d-qar
k apply -f luke.yaml

k exec -it r2-d2 -- curl luke
```

## Deploy Luke as a pod too

```
k apply -f jedi.yaml
k exec -it r2-d2 -- curl luke
```

Responses could come from the external endpoint or from the pod

## Network policy

```
k apply -f protect.yaml
```

R2-D2 can curl to luke, but kylo-ren can't
