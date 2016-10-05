#!/bin/bash

HOSTS="kube-adm-1 kube-node-1 kube-node-2"

gcloud compute instances create \
  $HOSTS \
  --boot-disk-size=20GB \
  --description=kube-adm-1 \
  --machine-type=n1-standard-1 \
  --image-project=ubuntu-os-cloud \
  --image-family=ubuntu-1604-lts \
  --zone=us-central1-a

for HOST in $HOSTS; do
  gcloud compute copy-files scripts/install_packages.sh ${HOST}:~ --zone us-central1-a  
done

gcloud compute copy-files scripts/init_master.sh kube-adm-1:~ --zone us-central1-a  
gcloud compute copy-files scripts/install_weave.sh kube-adm-1:~ --zone us-central1-a  
