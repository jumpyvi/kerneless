FROM quay.io/centos/centos:stream10 AS fetch-centos-kernel
RUN dnf install -y \
    dnf-plugins-core \
    cpio \
    binutils \
    xz

ENV BUILD_DIR=/tmp/kernel-build
WORKDIR ${BUILD_DIR}

RUN dnf download -y \
    kernel-core \
    kernel-modules \
    kernel-devel

RUN mkdir -p ${BUILD_DIR}/extracted

RUN for rpm in *.rpm; do \
    rpm2cpio "$rpm" | cpio -idmv -D ${BUILD_DIR}/extracted; \
    done

WORKDIR /system_files/kernel
RUN mkdir -p boot lib/modules usr/src

# The modules are not here, need to fix
RUN KABI=$(ls ${BUILD_DIR}/extracted/lib/modules) && \
    echo "Detected KABI: $KABI" && \
    echo "$KABI" > /kernel.abi && \
    \
    cp -v ${BUILD_DIR}/extracted/lib/modules/$KABI/vmlinuz boot/vmlinuz && \
    cp -v ${BUILD_DIR}/extracted/lib/modules/$KABI/config boot/config && \
    cp -v ${BUILD_DIR}/extracted/lib/modules/$KABI/System.map boot/System.map && \
    \
    cp -av ${BUILD_DIR}/extracted/lib/modules/$KABI lib/modules/ && \
    \
    cp -av ${BUILD_DIR}/extracted/usr/src/kernels/$KABI usr/src/

RUN dnf install -y tree && tree -L 3 lib/modules/

RUN KABI=$(basename $(ls lib/modules)) && \
    echo "Detected CentOS kernel ABI: $KABI" && \
    echo "$KABI" > /kernel.abi

RUN ls -la boot/

RUN --mount=type=bind,source=./scripts/setup-kernel.sh,target=/tmp/setup-kernel.sh \
    install -m 0755 /tmp/setup-kernel.sh /system_files/kernel/setup-kernel.sh

FROM scratch as centos-kernel

COPY --from=fetch-centos-kernel /system_files /system_files
COPY --from=fetch-centos-kernel /kernel.abi /kernel.abi