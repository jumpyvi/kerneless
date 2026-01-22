FROM alpine:edge AS fetch-cachy-kernel

RUN apk add --no-cache \
    wget \
    zstd \
    tar \
    ca-certificates \
    curl \
    wget

ENV BUILD_DIR=/tmp/kernel-build
WORKDIR ${BUILD_DIR}

RUN KERNEL_URL="$(curl -fsSL https://mirror.cachyos.org/repo/x86_64_v3/cachyos-v3/ \
    | grep -oE 'linux-cachyos-lts-[^"]*x86_64_v3\.pkg\.tar\.zst' \
    | grep -Ev '(lto|headers|nvidia|zfs)' \
    | head -n1 \
    | sed 's|^|https://mirror.cachyos.org/repo/x86_64_v3/cachyos-v3/|')" \
    && test -n "$KERNEL_URL" \
    && echo "KERNEL_URL=${KERNEL_URL}" >> /etc/environment

RUN HEADERS_URL="$(curl -fsSL https://mirror.cachyos.org/repo/x86_64_v3/cachyos-v3/ \
    | grep -oE 'linux-cachyos-lts-headers-[^"]*x86_64_v3\.pkg\.tar\.zst' \
    | grep -Ev '(lto|nvidia|zfs)' \
    | head -n1 \
    | sed 's|^|https://mirror.cachyos.org/repo/x86_64_v3/cachyos-v3/|')" \
    && test -n "$HEADERS_URL" \
    && echo "HEADERS_URL=${HEADERS_URL}" >> /etc/environment

ENV KERNEL_URL=${KERNEL_URL}
ENV HEADERS_URL=${HEADERS_URL}

RUN set -eux; \
    . /etc/environment; \
    wget -q "$KERNEL_URL" "$HEADERS_URL"

RUN set -eux; \
    . /etc/environment; \
    mkdir -p extracted; \
    tar -I zstd -xf "$(basename "$KERNEL_URL")" -C extracted --no-same-owner; \
    tar -I zstd -xf "$(basename "$HEADERS_URL")" -C extracted --no-same-owner

WORKDIR /system_files/kernel
RUN mkdir -p boot lib/modules usr/src

RUN KABI=$(ls ${BUILD_DIR}/extracted/usr/lib/modules/ | head -n 1) && \
    echo "Detected kernel ABI: $KABI" && \
    echo "$KABI" > /kernel.abi

RUN KABI=$(cat /kernel.abi) && \
    cp ${BUILD_DIR}/extracted/usr/lib/modules/${KABI}/vmlinuz boot/vmlinuz && \
    cp -a ${BUILD_DIR}/extracted/usr/lib/modules/${KABI} lib/modules/ && \
    cp -a ${BUILD_DIR}/extracted/usr/src/* usr/src/

RUN --mount=type=bind,source=./scripts/setup-kernel.sh,target=/tmp/setup-kernel.sh \
    install -m 0755 /tmp/setup-kernel.sh /system_files/kernel/setup-kernel.sh

FROM scratch as cachy-kernel

COPY --from=fetch-cachy-kernel /system_files /system_files
COPY --from=fetch-cachy-kernel /kernel.abi /kernel.abi