FROM ubuntu:19.10

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


ENTRYPOINT [ "/usr/local/bin/entrypoint", "/sbin/init" ]
