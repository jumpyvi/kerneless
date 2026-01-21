FROM alpine:edge AS fetch-alpine-kernel

RUN apk add --no-cache \
    wget \
    tar \
    xz \
    tree

ENV BUILD_DIR=/tmp/kernel-build
WORKDIR ${BUILD_DIR}

# Download kernel packages
RUN apk fetch --no-cache \
    linux-lts \
    linux-lts-dev

RUN mkdir -p /tmp/kernel-build/extracted
RUN for pkg in linux-lts-*.apk; do \
    tar -xzf "$pkg" -C /tmp/kernel-build/extracted; \
    done

RUN ls -la /tmp/kernel-build/extracted/boot/

WORKDIR /system_files/kernel
RUN mkdir -p boot lib/modules usr/src

# Copy kernel files, missing network virtio drivers
RUN cp -v ${BUILD_DIR}/extracted/boot/vmlinuz-lts boot/vmlinuz && \
    cp -v ${BUILD_DIR}/extracted/boot/config* boot/config && \
    cp -v ${BUILD_DIR}/extracted/boot/System.map* boot/System.map && \
    if [ -d ${BUILD_DIR}/extracted/lib/modules ]; then \
    cp -av ${BUILD_DIR}/extracted/lib/modules/* lib/modules/; \
    fi && \
    if [ -d ${BUILD_DIR}/extracted/usr/src ]; then \
    cp -av ${BUILD_DIR}/extracted/usr/src/* usr/src/; \
    fi

RUN tree -L 3 lib/modules/

# Detect kernel version
RUN KABI=$(cd lib/modules && ls -1 | head -n1) && \
    echo "Detected kernel ABI: $KABI" && \
    echo "$KABI" > /kernel.abi

RUN ls -la boot/

RUN --mount=type=bind,source=./scripts/setup-kernel.sh,target=/tmp/setup-kernel.sh \
    install -m 0755 /tmp/setup-kernel.sh /system_files/kernel/setup-kernel.sh

FROM scratch as alpine-kernel

COPY --from=fetch-alpine-kernel /system_files /system_files
COPY --from=fetch-alpine-kernel /kernel.abi /kernel.abi