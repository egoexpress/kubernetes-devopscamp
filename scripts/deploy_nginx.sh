#!/bin/bash

# run 2 instances of egoexpress/nginx-host container
kubectl run \
  devops-nginx \
  --image=egoexpress/nginx-host \
  --replicas=2 \
  --port=80

# expose service on every node with a random port
kubectl expose deployment \
  devops-nginx \
  --port=80 \
  --type=NodePort

# show service description
kubectl describe svc devops-nginx
