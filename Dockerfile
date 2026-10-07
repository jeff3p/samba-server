FROM registry.suse.com/bci/bci-base:15.7 AS builder

RUN mkdir -p /rootfs/etc/zypp/repos.d \
    && cp -a /etc/zypp/repos.d/. /rootfs/etc/zypp/repos.d/ \
    && zypper --root /rootfs --releasever 15.7 --non-interactive \
       install --no-recommends nfs-ganesha nfs-ganesha-vfs \
    && rm -rf /rootfs/var/cache/zypp/*

FROM registry.suse.com/bci/bci-minimal:15.7

COPY --from=builder /rootfs/ /

USER 0

RUN mkdir -p /export /etc/ganesha /var/lib/nfs /run/ganesha

EXPOSE 2049/tcp

CMD ["ganesha.nfsd", "-F", "-L", "/dev/stdout", "-f", "/etc/ganesha/ganesha.conf"]
