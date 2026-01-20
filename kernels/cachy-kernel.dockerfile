FROM ubuntu:26.04 AS fetch-cachy-kernel

RUN apt-get update && apt-get install -y \
    wget \
    zstd \
    tar \
    ca-certificates

ENV BUILD_DIR=/tmp/kernel-build
WORKDIR ${BUILD_DIR}

# Static url for now
ENV KERNEL_URL=https://cdn77.cachyos.org/repo/x86_64_v4/cachyos-v4/linux-cachyos-lts-6.12.66-2-x86_64_v4.pkg.tar.zst
ENV HEADERS_URL=https://cdn77.cachyos.org/repo/x86_64_v4/cachyos-v4/linux-cachyos-lts-headers-6.12.66-2-x86_64_v4.pkg.tar.zst

RUN wget ${KERNEL_URL} && \
    wget ${HEADERS_URL}

RUN mkdir -p extracted && \
    tar -I zstd -xvf linux-cachyos-lts-6.12.66-2-x86_64_v4.pkg.tar.zst -C extracted --no-same-owner && \
    tar -I zstd -xvf linux-cachyos-lts-headers-6.12.66-2-x86_64_v4.pkg.tar.zst -C extracted --no-same-owner

WORKDIR /system_files/kernel
RUN mkdir -p boot lib/modules usr/src

RUN KABI=$(ls ${BUILD_DIR}/extracted/usr/lib/modules/ | head -n 1) && \
    echo "Detected kernel ABI: $KABI" && \
    echo "$KABI" > /kernel.abi

RUN KABI=$(cat /kernel.abi) && \
    cp -v ${BUILD_DIR}/extracted/usr/lib/modules/${KABI}/vmlinuz boot/vmlinuz && \
    cp -av ${BUILD_DIR}/extracted/usr/lib/modules/${KABI} lib/modules/ && \
    cp -av ${BUILD_DIR}/extracted/usr/src/* usr/src/

RUN --mount=type=bind,source=./scripts/setup-kernel.sh,target=/tmp/setup-kernel.sh \
    install -m 0755 /tmp/setup-kernel.sh /system_files/kernel/setup-kernel.sh

FROM scratch as cachy-kernel

COPY --from=fetch-cachy-kernel /system_files /system_files
COPY --from=fetch-cachy-kernel /kernel.abi /kernel.abi