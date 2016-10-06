# kubernetes-devopscamp

These scripts create (or destroy) 3 VM instances on Google Compute Engine (GCE). These VMs are used to demo the Kubernetes 
installation with kubeadm at [DevOps Camp Compact 2016](http://devops-camp.de) in Nuremberg.

## Setting the stage

### Setup the hosts

This demo uses 3 hosts (**kube-adm-1** for the master, **kube-node-1** and **kube-node-2** for the nodes). Out of convience these are set up on GCE using the _create_instances.sh_ script. It requires a properly setup Google Compute Engine environment (i.e. the gcloud binary is present and can talk to Google services). The script also makes sure to copy all the other scripts to setup Kubernetes to each node. 

Feel free to use your own (existing) servers instead of creating some on GCE. The only requirement here: **The hosts have to run Ubuntu 16.04 LTS** (or CentOS 7, check the sources below if you want to use that). Just clone the repo to all your hosts and follow along.

### Installing the required packages

Login to each of the 3 hosts and run _scripts/install_packages.sh_ to install the required DEB packages.

### Setting up the master

On the master (**kube-adm-1**) run _scripts/init_master.sh_ to initialize the Kubernetes master. Check the output for the _kubeadm join_ command that is printed on the last line. Save that command for later.

```shell
root@kube-adm-1:~# ./scripts/init_master.sh 
<master/tokens> generated token: "8f960a.55d7658e6d20720f"
<master/pki> created keys and certificates in "/etc/kubernetes/pki"
<util/kubeconfig> created "/etc/kubernetes/admin.conf"
<util/kubeconfig> created "/etc/kubernetes/kubelet.conf"
<master/apiclient> created API client configuration
<master/apiclient> created API client, waiting for the control plane to become ready
<master/apiclient> all control plane components are healthy after 44.817139 seconds
<master/apiclient> waiting for at least one node to register and become ready
<master/apiclient> first node is ready after 0.503231 seconds
<master/discovery> created essential addon: kube-discovery, waiting for it to become ready
<master/discovery> kube-discovery is ready after 10.503283 seconds
<master/addons> created essential addon: kube-proxy
<master/addons> created essential addon: kube-dns

Kubernetes master initialised successfully!

You can now join any number of machines by running the following on each node:

kubeadm join --token 8f960a.55d7658e6d20720f 10.128.0.4
```

### Setting up the nodes

Use the _kubeadm join_ command from the step before. Execute it on each node to let it join the Kubernetes cluster. If you want to add other nodes later on use that command as well.

```shell
root@kube-node-1:~# kubeadm join --token 8f960a.55d7658e6d20720f 10.128.0.4
<util/tokens> validating provided token
<node/discovery> created cluster info discovery client, requesting info from "http://10.128.0.4:9898/cluster-info/v1/?token-id=8f960a"
<node/discovery> cluster info object received, verifying signature using given token
<node/discovery> cluster info signature and contents are valid, will use API endpoints [https://10.128.0.4:443]
<node/csr> created API client to obtain unique certificate for this node, generating keys and certificate signing request
<node/csr> received signed certificate from the API server, generating kubelet configuration
<util/kubeconfig> created "/etc/kubernetes/kubelet.conf"

Node join complete:
* Certificate signing request sent to master and response
  received.
* Kubelet informed of new secure connection details.

Run 'kubectl get nodes' on the master to see this machine join.
```

### Install overlay network

We're almost there. To allow communication between containers, provide proper IP address allocation and DNS resolution an overlay network is required. There are several choices but [Weave Net](http://weave.works) seems to be the easiest one to use. Execute _scripts/install_weave.sh_ on the master (**kube-adm-1**) to set it up. If you join nodes in the cluster later on the cluster itself will make sure that Weave Net is installed on them as well.

### Profit

Here we are - you now have a running Kubernetes cluster with 2 nodes. By default pods will not be scheduled on the master itself, only on the nodes. If you want to use the master for some actual workload as well, execute _scripts/taint_master.sh_ on **kube-adm-1**.

## Running some workload

Now that you have a new and shiny Kubernetes cluster it's time to put it into use.

## Tearing down the stage

If you want to get rid of the cluster you set up using VMs on GCE, just execute _delete_instances.sh_ to tear down the nodes. If you used your own nodes use _scripts/deinstall_kubernetes.sh_ to get rid of Kubernetes. Warning: This deinstalls Docker itself as well, so make sure you want that. Otherwise change the script accordingly.

## Sources

* [Installing Kubernetes on Linux with kubeadm](http://kubernetes.io/docs/getting-started-guides/kubeadm/)
* [How we made Kubernetes insanely easy to install](http://blog.kubernetes.io/2016/09/how-we-made-kubernetes-easy-to-install.html)

