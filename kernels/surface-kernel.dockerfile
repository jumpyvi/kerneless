FROM alpine:latest AS fetch-surface-kernel

# Uses alpine, it's simple because the kernel is already hosted as an archive on github
RUN apk add --no-cache \
    curl \
    zstd \
    tar \
    wget \
    jq

ENV BUILD_DIR=/tmp/kernel-build
WORKDIR ${BUILD_DIR}

RUN curl -s https://api.github.com/repos/linux-surface/linux-surface/releases/latest \
    | jq -r '.assets[] \
    | select(.name \
    | test("^linux-surface-[0-9.]+\\.arch[0-9]+-[0-9]+-x86_64\\.pkg\\.tar\\.zst$")) \
    | .browser_download_url' | wget -i -

RUN mkdir -p extracted && \
    tar -I zstd -xvf linux-surface-*.pkg.tar.zst -C extracted --no-same-owner

WORKDIR /system_files/kernel
RUN mkdir -p boot lib/modules usr/src

RUN KABI=$(ls ${BUILD_DIR}/extracted/usr/lib/modules/ | head -n 1) && \
    echo "Detected kernel ABI: $KABI" && \
    echo "$KABI" > /kernel.abi

    
RUN KABI=$(cat /kernel.abi) && \
    cp ${BUILD_DIR}/extracted/usr/lib/modules/${KABI}/vmlinuz boot/vmlinuz && \
    cp -a ${BUILD_DIR}/extracted/usr/lib/modules/${KABI} lib/modules/

RUN --mount=type=bind,source=./scripts/setup-kernel.sh,target=/tmp/setup-kernel.sh \
    install -m 0755 /tmp/setup-kernel.sh /system_files/kernel/setup-kernel.sh

FROM scratch as surface-kernel

COPY --from=fetch-surface-kernel /system_files /system_files
COPY --from=fetch-surface-kernel /kernel.abi /kernel.abi