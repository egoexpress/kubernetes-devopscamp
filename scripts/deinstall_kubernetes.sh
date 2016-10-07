#!/bin/bash

systemctl stop kubelet;
docker rm -f $(docker ps -q); mount | grep "/var/lib/kubelet/*" | awk '{print $3}' | xargs umount 1>/dev/null 2>/dev/null;
rm -rf /var/lib/kubelet /etc/kubernetes /var/lib/etcd /etc/cni;
ip link set cbr0 down; ip link del cbr0;
ip link set cni0 down; ip link del cni0;
apt-get remove docker.io kubelet kubeadm kubectl kubernetes-cni
apt-get autoremove
