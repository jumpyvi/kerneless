ARG KERNEL
ARG KERNEL_IMAGE_BASE

FROM ${KERNEL_IMAGE_BASE}:${KERNEL} AS ctx
COPY / /build_files/ 

FROM ghcr.io/projectbluefin/dakota:latest

ARG KERNEL

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/system_files/kernel/setup-kernel.sh && \
    ostree container commit

RUN bootc container lint