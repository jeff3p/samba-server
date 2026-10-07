FROM registry.suse.com/bci/bci-base:15.7 AS builder

RUN mkdir -p /rootfs/etc/zypp/repos.d \
    && cp -a /etc/zypp/repos.d/. /rootfs/etc/zypp/repos.d/ \
    && zypper --root /rootfs --releasever 15.7 --non-interactive \
       install --no-recommends samba shadow bash coreutils \
    && rm -rf /rootfs/var/cache/zypp/*

FROM registry.suse.com/bci/bci-minimal:15.7

COPY --from=builder /rootfs/ /

USER 0

RUN mkdir -p /etc/samba /usr/local/bin \
    && printf '%s\n' \
       '[global]' \
       '    server role = standalone server' \
       '    security = user' \
       '    map to guest = Never' \
       '    server min protocol = SMB2_02' \
       '    smb ports = 445' \
       '    disable netbios = yes' \
       '    load printers = no' \
       '    disable spoolss = yes' \
       '    printing = bsd' \
       '    printcap name = /dev/null' \
       '    logging = file' \
       '    log file = /dev/stdout' \
       '    max log size = 0' \
       '' \
       '[shared]' \
       '    path = /share' \
       '    browseable = yes' \
       '    read only = no' \
       '    guest ok = no' \
       '    valid users = smbuser' \
       '    create mask = 0660' \
       '    directory mask = 0770' \
       > /etc/samba/smb.conf \
    && printf '%s\n' \
       '#!/bin/bash' \
       'set -euo pipefail' \
       ': "${SMB_PASSWORD:?SMB_PASSWORD must be supplied}"' \
       'printf "%s\n%s\n" "$SMB_PASSWORD" "$SMB_PASSWORD" | smbpasswd -s -a smbuser' \
       'unset SMB_PASSWORD' \
       'chown smbuser:smbuser /share' \
       'chmod 0770 /share' \
       'exec smbd --foreground --no-process-group --debug-stdout' \
       > /usr/local/bin/entrypoint.sh \
    && chmod 0755 /usr/local/bin/entrypoint.sh \
    && useradd --no-create-home --shell /bin/false smbuser \
    && mkdir -p /share /run/samba /var/lib/samba/private \
    && chmod 0700 /var/lib/samba/private

EXPOSE 445/tcp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
