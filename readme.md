
## Start up our compute

Since we're building a Kubernetes cluster using docker containers as compute instead of VM's 
we'll need to build our base dockerfile.

```
docker-compose build
docker-compose up -d
```

This dockerfile would represent our "ubuntu" VM's.
It has `systemd` installed with workarounds to get `systemd` working inside docker


## Access our master

```
docker exec -it master-a bash
```


## Install Kubernetes

I've already installed all Kubernetes packages in the base image to save time.
See (dockerfile)[./dockerfile]

When running nodes in docker we don't want to use dockers internal dns <br/>
If you do, coredns will get a dns loopback error <br/>

```
bash -c 'cat <<EOF >/etc/resolv.conf
nameserver 8.8.8.8
EOF'

kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors Swap,SystemVerification

systemctl stop kubelet.service
echo "failSwapOn: false" >> /var/lib/kubelet/config.yaml
systemctl start kubelet.service
systemctl status kubelet.service

#redo init - ignore few checks since files already exists and ports are already in use

kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors "Swap,SystemVerification,Port-6443,Port-10259,Port-10257,FileAvailable--etc-kubernetes-manifests-kube-apiserver.yaml,FileAvailable--etc-kubernetes-manifests-kube-controller-manager.yaml,FileAvailable--etc-kubernetes-manifests-kube-scheduler.yaml,FileAvailable--etc-kubernetes-manifests-etcd.yaml,Port-10250,Port-2379,Port-2380,DirAvailable--var-lib-etcd"

systemctl stop kubelet.service
echo "failSwapOn: false" >> /var/lib/kubelet/config.yaml
systemctl start kubelet.service
systemctl status kubelet.service

#in case of failure
journalctl -xeu kubelet

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

#setup the pod network
kubectl apply -f calico.yaml

```