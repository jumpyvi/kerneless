FROM ubuntu:26.04 AS fetch-ubuntu-kernel

RUN apt-get update && apt-get install -y \
    wget \
    zstd \
    tar \
    binutils

ENV BUILD_DIR=/tmp/kernel-build
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR ${BUILD_DIR}

RUN apt-get install -y --download-only --no-install-recommends \
    linux-image-generic \
    linux-headers-generic

RUN mv /var/cache/apt/archives/linux-headers-*.deb . && \
    mv /var/cache/apt/archives/linux-image-*-generic_*.deb . && \
    mv /var/cache/apt/archives/linux-modules-*.deb .

RUN rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

RUN mkdir -p /tmp/kernel-build/extracted

RUN ar x linux-image-*-generic_*_amd64.deb && \
    tar -xvf data.tar* -C /tmp/kernel-build/extracted --no-same-owner && \
    rm -f data.tar* control.tar.* debian-binary && \
    \
    ar x linux-headers-*_*.8_all.deb && \
    tar -xvf data.tar* -C /tmp/kernel-build/extracted --no-same-owner && \
    rm -f data.tar* control.tar.* debian-binary && \
    \
    ar x linux-headers-*-generic_*_amd64.deb && \
    tar -xvf data.tar* -C /tmp/kernel-build/extracted --no-same-owner && \
    rm -f data.tar* control.tar.* debian-binary && \
    \
    ar x linux-modules-*-generic_*_amd64.deb && \
    tar -xvf data.tar* -C /tmp/kernel-build/extracted --no-same-owner && \
    rm -f data.tar* control.tar.* debian-binary

RUN ls -la /tmp/kernel-build/extracted/boot/

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

FROM scratch as ubuntu-kernel

COPY --from=fetch-ubuntu-kernel /system_files /system_files
COPY --from=fetch-ubuntu-kernel /kernel.abi /kernel.abi