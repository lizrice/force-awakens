#!/bin/bash

docker network disconnect kind kind-registry
kind delete cluster --name jakku
kind delete cluster --name d-qar
