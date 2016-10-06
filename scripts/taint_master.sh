#!/bin/bash

# allow pods to run on the Kubernetes master as well
kubectl taint nodes --all dedicated-
