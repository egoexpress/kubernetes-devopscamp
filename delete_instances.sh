#!/bin/bash

gcloud compute instances delete \
  kube-adm-1 kube-node-1 kube-node-2 \
  --zone=us-central1-a \
  --delete-disks=all
  
