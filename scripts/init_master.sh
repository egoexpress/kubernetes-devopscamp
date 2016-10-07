#!/bin/bash

# initialize Kubernetes master
kubeadm init

# setup Weave Net overlay network
kubectl apply -f https://git.io/weave-kube
