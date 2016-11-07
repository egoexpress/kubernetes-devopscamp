# kubernetes-devopscamp

This documentaton and the contained scripts create VM instances on [Google Compute Engine](https://cloud.google.com/compute/) (GCE) and demo the Kubernetes installation with kubeadm. This was presented in a talk at [DevOps Camp Compact 2016](http://devops-camp.de) in Nuremberg.

You can also use these scripts to setup Kubernetes in a quick way on your own machines, be it physical ones, VMs or instances on some cloud provider like AWS.

## Setting the stage

### Setup the hosts

This demo uses 3 hosts (**kube-master-1** for the master, **kube-node-1** and **kube-node-2** for the nodes). Out of convience these are created on GCE using the _create_instances.sh_ script. It requires a properly setup Google Compute Engine environment (i.e. the gcloud binary is present and can talk to Google services). The script also makes sure to copy all the other scripts to setup Kubernetes to each node. 

Feel free to use your own (existing) servers instead of creating some on GCE. The only requirement here: **The hosts have to run Ubuntu 16.04 LTS** (or CentOS 7, check the sources below if you want to use that). Just clone the repo to all your hosts and follow along.

### Installing the required packages

Login to each of the 3 hosts and run _scripts/install_packages.sh_ to install the required DEB packages.

### Setting up the master

On the master (**kube-master-1**) run _scripts/init_master.sh_ to initialize the Kubernetes master. This also initializes the overlay network. It is needed to allow communication between containers, provide proper IP address allocation and DNS resolution. There are several choices but [Weave Net](http://weave.works) seems to be the easiest one to use. If you join nodes in the cluster later on the cluster itself will make sure that Weave Net is installed on them as well.

Check the output for the _kubeadm join_ command in the penultimate line. Save that command for later.

```shell
root@kube-master-1:~# ./scripts/init_master.sh 
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
daemonset "weave-net" created
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

### Profit

Here we are - you now have a running Kubernetes cluster with 2 nodes. By default pods will not be scheduled on the master itself, only on the nodes. If you want to use the master for some actual workload as well, execute _scripts/taint_master.sh_ on **kube-master-1**.

To make sure everything is set up and running use _kubectl get pods --all-namespaces_ to get the state of the system pods

```shell
root@kube-master-1:~# kubectl get pods --all-namespaces -o wide
NAMESPACE     NAME                                 READY     STATUS    RESTARTS   AGE       IP           NODE
kube-system   etcd-kube-master-1                      1/1       Running   0          2m        10.128.0.4   kube-master-1
kube-system   kube-apiserver-kube-master-1            1/1       Running   2          2m        10.128.0.4   kube-master-1
kube-system   kube-controller-manager-kube-master-1   1/1       Running   0          2m        10.128.0.4   kube-master-1
kube-system   kube-discovery-982812725-1fd2g       1/1       Running   0          3m        10.128.0.4   kube-master-1
kube-system   kube-dns-2247936740-69368            3/3       Running   0          3m        10.32.0.2    kube-master-1
kube-system   kube-proxy-amd64-dvotl               1/1       Running   0          3m        10.128.0.4   kube-master-1
kube-system   kube-proxy-amd64-z9u3b               1/1       Running   0          2m        10.128.0.2   kube-node-1
kube-system   kube-proxy-amd64-s7a3e               1/1       Running   0          2m        10.128.0.6   kube-node-2
kube-system   kube-scheduler-kube-master-1            1/1       Running   0          2m        10.128.0.4   kube-master-1
kube-system   weave-net-9gkv5                      2/2       Running   0          1m        10.128.0.2   kube-node-1
kube-system   weave-net-1a4x1                      2/2       Running   0          1m        10.128.0.6   kube-node-2
kube-system   weave-net-mcnei                      2/2       Running   0          1m        10.128.0.4   kube-master-1
```

## Running nginx

Now that you have a new and shiny Kubernetes cluster it's time to put it into use. The demo will deploy two nginx instances and a corresponding service. Use _scripts/deploy_nginx.sh_ on **kube-master-1** to execute the required steps.

```shell
root@kube-master-1:~# ./scripts/deploy_nginx.sh 
deployment "devops-nginx" created
service "devops-nginx" exposed
Name:                   devops-nginx
Namespace:              default
Labels:                 run=devops-nginx
Selector:               run=devops-nginx
Type:                   NodePort
IP:                     100.74.218.188
Port:                   <unset> 80/TCP
NodePort:               <unset> 32025/TCP
Endpoints:              <none>
Session Affinity:       None
```

Note the port listed under _NodePort_. This is the port you will use to connect to your nginx instances. The service binds this port to all cluster nodes, so use any public IP of your nodes.

## Checking nginx

Get the public IPs of your nodes. In this example the IPs are 108.59.81.224 and 8.34.214.125 as seen in the output from _gcloud_. If you use your own nodes use their public IPs accordingly.

```shell
$ gcloud compute instances list
NAME         ZONE           MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP      STATUS
kube-master-1   us-central1-a  n1-standard-1               10.128.0.4   130.211.176.210  RUNNING
kube-node-1  us-central1-a  n1-standard-1               10.128.0.2   108.59.81.224    RUNNING
kube-node-2  us-central1-a  n1-standard-1               10.128.0.3   8.34.214.125     RUNNING
```

Now first check all the running pods and then connect to nginx using curl. Use one of the public IPs (108.59.81.224 in this example) and the port from the _NodePort_ line above (here: 32025).
As you'll see, by just connecting to one IP your request will be route to any of the pods, even if it runs on another node. How's that for high availability?

```shell
root@kube-master-1:~# kubectl get pods
NAME                            READY     STATUS    RESTARTS   AGE
devops-nginx-2330576289-1gepk   1/1       Running   0          3m
devops-nginx-2330576289-t7vjj   1/1       Running   0          3m
root@kube-master-1:~# curl http://108.59.81.224:32025
<h2>
This is Nginx running on
devops-nginx-2330576289-t7vjj:80
</h2>
root@kube-master-1:~# curl http://108.59.81.224:32025
<h2>
This is Nginx running on
devops-nginx-2330576289-1gepk:80
</h2>
```

## Scaling up

Now that we have just two pods running we want more. Scale up! Use _scripts/scale_nginx.sh_ to add two more pods. They will be automatically added to the service created above so repeating the _curl_ command from before should show that requests will be routed to the new pods as well. Use _scripts/show_nginx.sh_ to see all the details of your running deployment and service.

## Setting a fixed port

As you may have noticed the port for the service created above (32025 in the example) is chosen randomly (within the range of 30000-32767). If you want to have a fixed port (that must also be within this range) you have to use a service configuration file as kubectl doesn't have an option for that. Use _kubectl create_ with the file _deploy/devops-nginx-svc.yaml_ to set up the service on port 31000.

```shell
root@kube-master-1:~# kubectl delete svc devops-nginx
service "devops-nginx" deleted
root@kube-master-1:~# kubectl create -f deploy/devops-nginx-svc.yaml 
service "devops-nginx" created
root@kube-master-1:~# kubectl describe svc devops-nginx
Name:                   devops-nginx
Namespace:              default
Labels:                 name=devops-nginx
Selector:               run=devops-nginx
Type:                   NodePort
IP:                     100.73.57.228
Port:                   <unset> 80/TCP
NodePort:               <unset> 31000/TCP
Endpoints:              10.40.0.1:80,10.40.0.2:80
Session Affinity:       None
No events.
root@kube-master-1:~# curl http://108.59.81.224:31000
<h2>
This is Nginx running on
devops-nginx-2330576289-1gepk:80
</h2>
root@kube-master-1:~# curl http://108.59.81.224:31000
<h2>
This is Nginx running on
devops-nginx-2330576289-t7vjj:80
</h2>
```

## Tearing down the stage

If you want to get rid of the cluster you set up using VMs on GCE, just execute _delete_instances.sh_ to tear down the nodes. If you used your own nodes use _scripts/deinstall_kubernetes.sh_ to get rid of Kubernetes. Warning: This deinstalls Docker itself as well, so make sure you want that. Otherwise change the script accordingly.

If you just want to reset the Kubernetes environment and start over again use the script _scripts/reset_kubernetes.sh_. 
*Note:* The command used herein was introduced in kubeadm 1.5, so this will not work in kubeadm 1.4.

## Sources/Further reading

* [Installing Kubernetes on Linux with kubeadm](http://kubernetes.io/docs/getting-started-guides/kubeadm/)
* [How we made Kubernetes insanely easy to install](http://blog.kubernetes.io/2016/09/how-we-made-kubernetes-easy-to-install.html)
* [Setting up Kubernetes on Ubuntu (the old way)](http://kubernetes.io/docs/getting-started-guides/ubuntu/)
* [Issue #11 at Kubernetes feature repository for kubeadm development](https://github.com/kubernetes/features/issues/11)
* [How kubeadm initializes your Kubernetes master](https://www.ianlewis.org/en/how-kubeadm-initializes-your-kubernetes-master)
