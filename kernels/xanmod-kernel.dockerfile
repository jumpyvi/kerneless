FROM ubuntu:26.04 AS fetch-xanmod-kernel
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget \
    zstd \
    tar \
    binutils \
    gnupg \
    ca-certificates \
    lsb-release \
    xz-utils

ENV BUILD_DIR=/tmp/kernel-build

WORKDIR ${BUILD_DIR}

RUN install -m 0755 -d /etc/apt/keyrings && \
    wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -vo /etc/apt/keyrings/xanmod-archive-keyring.gpg

RUN cat <<EOF | tee /etc/apt/sources.list.d/xanmod.sources
Types: deb
URIs: http://deb.xanmod.org
Suites: $(lsb_release -sc)
Components: main
Signed-By: /etc/apt/keyrings/xanmod-archive-keyring.gpg
EOF

RUN apt-get update -y && apt-get install -y --download-only --no-install-recommends \
    linux-xanmod-lts-x64v3

RUN ls -la /var/cache/apt/archives/

RUN mv /var/cache/apt/archives/linux-image-*-xanmod*_amd64.deb . && \
    mv /var/cache/apt/archives/linux-headers-*-xanmod*_amd64.deb .

RUN rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

RUN mkdir -p /tmp/kernel-build/extracted

RUN ar x linux-image-*-xanmod*_amd64.deb && \
    tar -xvf data.tar* -C /tmp/kernel-build/extracted --no-same-owner && \
    rm -f data.tar* control.tar.* debian-binary && \
    \
    ar x linux-headers-*-xanmod*_amd64.deb && \
    tar -xvf data.tar* -C /tmp/kernel-build/extracted --no-same-owner && \
    rm -f data.tar* control.tar.* debian-binary

WORKDIR /system_files/kernel
RUN mkdir -p boot lib/modules usr/src

RUN cp -v ${BUILD_DIR}/extracted/boot/vmlinuz* boot/vmlinuz && \
    cp -v ${BUILD_DIR}/extracted/boot/config* boot/config && \
    cp -v ${BUILD_DIR}/extracted/boot/System.map* boot/System.map && \
    cp -av ${BUILD_DIR}/extracted/lib/modules/* lib/modules/ && \
    cp -av ${BUILD_DIR}/extracted/usr/src/* usr/src/

RUN KABI=$(basename $(ls lib/modules)) && \
    echo "Detected kernel ABI: $KABI" && \
    echo "$KABI" > /kernel.abi

RUN --mount=type=bind,source=./scripts/setup-kernel.sh,target=/tmp/setup-kernel.sh \
    install -m 0755 /tmp/setup-kernel.sh /system_files/kernel/setup-kernel.sh

FROM scratch as xanmod-kernel

COPY --from=fetch-xanmod-kernel /system_files /system_files
COPY --from=fetch-xanmod-kernel /kernel.abi /kernel.abi