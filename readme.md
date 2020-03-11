
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

#disable swap on kubelet config

nano /var/lib/kubelet/config.yaml

`failSwapOn: false`

kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors Swap,SystemVerification


```
