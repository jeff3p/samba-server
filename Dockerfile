FROM registry.opensuse.org/opensuse/tumbleweed:latest

RUN zypper --non-interactive refresh \
    && zypper --non-interactive install --no-recommends \
       nfs-ganesha nfs-ganesha-vfs \
    && zypper clean --all \
    && mkdir -p /export /etc/ganesha /var/lib/nfs /run/ganesha

USER 0

EXPOSE 2049/tcp

CMD ["ganesha.nfsd", "-F", "-L", "/dev/stdout", "-f", "/etc/ganesha/ganesha.conf"]
