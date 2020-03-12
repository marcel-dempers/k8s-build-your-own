FROM ubuntu:19.10

#INSTALL COMPONENTS TO MAKE THIS CONTAINER BEHAVE AS A VM
# * INSTALL SYSTEMD
# * CUSTOM ENTRYPOINT THAT FIXES THINGS - from K8s SIGS Kind
#################################################################
#Install known tools required for the guide
#We use systemd to bootstrap the cluster components
RUN apt-get update && apt-get install -y --no-install-recommends systemd bash ca-certificates curl 

RUN apt-get clean -y && \
   rm -rf \
   /var/cache/debconf/* \
   /var/lib/apt/lists/* \
   /var/log/* \
   /tmp/* \
   /var/tmp/* \
   /usr/share/doc/* \
   /usr/share/man/* \
   /usr/share/local/*

RUN find /lib/systemd/system/sysinit.target.wants/ -name "systemd-tmpfiles-setup.service" -delete \
    && rm -f /lib/systemd/system/multi-user.target.wants/* \
    && rm -f /etc/systemd/system/*.wants/* \
    && rm -f /lib/systemd/system/local-fs.target.wants/* \
    && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
    && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
    && rm -f /lib/systemd/system/basic.target.wants/* \
    && echo "ReadKMsg=no" >> /etc/systemd/journald.conf \
    && ln -s "$(which systemd)" /sbin/init

COPY ./entrypoint /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

# tell systemd that it is in docker (it will check for the container env)
# https://www.freedesktop.org/wiki/Software/systemd/ContainerInterface/
ENV container docker

# systemd exits on SIGRTMIN+3, not SIGTERM (which re-executes it)
# https://bugzilla.redhat.com/show_bug.cgi?id=1201657
STOPSIGNAL SIGRTMIN+3

################################################################

#Install Kubernetes Packages

RUN apt-get update && apt-get install -y curl wget gnupg2 nano

#add GPG key + apt repo for Kubernetes
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update

#install packages and mark as hold
RUN apt-get install -y docker.io kubelet kubeadm kubectl && \
    apt-mark hold docker.io kubelet kubeadm kubectl

ENTRYPOINT [ "/usr/local/bin/entrypoint", "/sbin/init" ]
