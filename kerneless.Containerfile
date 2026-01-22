ARG KERNEL

FROM scratch AS ctx
COPY build_files /

ARG KERNEL # Is set from the Github Actions
FROM ${KERNEL}

ARG TYPE

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh "${TYPE}" && \
    ostree container commit

RUN bootc container lint