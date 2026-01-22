ARG KERNEL

FROM scratch AS ctx

ARG KERNEL

COPY --from=ghcr.io/jumpyvi/kerneless:${KERNEL} /system_files/kernel /files/system_files/kernel

FROM ghcr.io/projectbluefin/dakota:latest

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/system_files/kernel/setup-kernel.sh && \
    ostree container commit

RUN bootc container lint