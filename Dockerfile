FROM centos
USER root
COPY . /tmp/src

RUN yum install git xz-devel wget make gcc syslinux mkisofs -y && \
    awk 'NF{$0="set "$0}1' /tmp/src/inventory > /tmp/src/vars.ipxe && \
    cat /tmp/src/header.ipxe /tmp/src/vars.ipxe /tmp/src/footer.ipxe > /tmp/src/custom.ipxe && \
    git clone https://github.com/ipxe/ipxe/ && \
    cd ipxe/src && \
    cp -rf /tmp/src/settings.h config/settings.h && \
    make bin/ipxe.iso EMBED=/tmp/src/custom.ipxe && \
    make bin-x86_64-efi/ipxe.iso EMBED=/tmp/src/custom.ipxe
