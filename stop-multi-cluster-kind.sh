#!/bin/bash

docker network disconnect kind kind-registry
kind delete cluster -n jakku
kind delete cluster -n d-qar
