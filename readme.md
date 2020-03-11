
## Start up our compute

Since we're building a Kubernetes cluster using docker containers as compute instead of VM's 
we'll need to build our base dockerfile.

This dockerfile would represent our "ubuntu" VM's.

```
docker-compose up -d
```

## Access the compute

```
docker exec -it node-a bash
```

## Install Kubernetes

Do this on all nodes

```
#when running nodes in docker we don't want to use dockers internal dns
#if you do, coredns will get a dns loopback error

bash -c 'cat <<EOF >/etc/resolv.conf
nameserver 8.8.8.8
EOF'

apt-get update && apt-get install -y curl wget gnupg2 nano

#add GPG key + apt repo for Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
bash -c 'cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF' && \
apt-get update

#OPTIONAL: check versions of packages available
apt-cache policy kubelet | head -n 20 
apt-cache policy docker.io | head -n 20 

#install packages and mark as hold
apt-get install -y docker.io kubelet kubeadm kubectl && \
apt-mark hold docker.io kubelet kubeadm kubectl

systemctl enable kubelet.service && systemctl start kubelet.service
systemctl enable docker.service && systemctl start docker.service

systemctl status docker.service

```

## Boostrap the Master

```

#grab our pods network manifest

#Notes:
# Docker container has swap enabled. [ignore]
# Docker does not do modprobe [ignore]


``
#init kubelet will fail on first run.
#we need it to generate /var/lib/kubelet/config.yaml

kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors Swap,SystemVerification

#disable swap on kubelet config
echo "failSwapOn: false" >> /var/lib/kubelet/config.yaml

#redo init - ignore few checks since files already exists and ports are already in use

kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors "Swap,SystemVerification,Port-6443,Port-10259,Port-10257,FileAvailable--etc-kubernetes-manifests-kube-apiserver.yaml,FileAvailable--etc-kubernetes-manifests-kube-controller-manager.yaml,FileAvailable--etc-kubernetes-manifests-kube-scheduler.yaml,FileAvailable--etc-kubernetes-manifests-etcd.yaml,Port-10250,Port-2379,Port-2380,DirAvailable--var-lib-etcd"

#troubleshoot kubelet
journalctl -xeu kubelet

#you may have to add 

```

```
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

#setup the pod network
kubectl apply -f calico.yaml
```