#!/bin/bash

# show all pods (except Kubernetes system pods)
kubectl get pods -o wide

# show all deployments
kubectl get deployments

# show service description
kubectl describe svc devops-nginx
