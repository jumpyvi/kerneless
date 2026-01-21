# Pre-built kernels as OCI containers
> [!WARNING]
This is experimental 🦖! Only run in a test VM!

Run custom kernels on ProjectBluefin's Dakota based images!

(Silverblue 43+ support might comme soon)

Feel free to use the code in this repo in any ways you wish

## Available kernels:

### Ubuntu LTS
The latest LTS Ubuntu kernel, tested and relied upon by thousand of users.

>Right now this is on the pre-release of Resolute Racoon, it will follow the current LTS release when Resolute is released.

https://ubuntu.com/kernel



----------

### Bazzite rolling kernel

The latest Bazzite kernel, used in the popular Bazzite operating system. Optimized for gaming devices.

https://github.com/bazzite-org/kernel-bazzite

------

### Cachy LTS

The latest LTS CachyOS kernel, designed for improved performance.
No utils, just the kernel, modules and headers

https://github.com/CachyOS/linux-cachyos

-----

### Surface Rolling
> 🧪 Works in qemu, not tested on a real Surface

The latest Surface kernel for GitHub, includes patches for Microsoft Surfaces.
Does not support arm or nvidia

https://github.com/linux-surface/linux-surface

Follows the latest surface kernel available on GitHub for Arch

---

### XanMod LTS (v3)

The LTS XanMod kernel, built to provide a stable, smooth and solid system experience.
Notably Includes `sched_ext` and `binder_linux`

https://xanmod.org/

Follows the latest LTS XanMod kernel available on Ubuntu LTS

---

Experimentals kernels from [Alpine](kernels/experimentals/alpine-kernel.dockerfile) and [Centos](kernels/experimentals/WIP.centos-kernel.dockerfile) are also available, but are not maintained and have severe issues.

## Setup
> [!NOTE]
Github Actions will come eventually, for now it's manual

1. Fetch the kernel you want with `just --choose`


2. Near the top of the Containerfile, in scratch
```
COPY --from=localhost/{name}-kernel:latest /system_files/kernel /files/system_files/kernel
```

1. In the actual base image container
```
RUN /ctx/files/system_files/kernel/setup-kernel.sh
```

### Working exemple
> Based on https://github.com/ublue-os/image-template
```
FROM scratch AS ctx
COPY build_files /
COPY --from=localhost/xanmod-kernel:latest /system_files/kernel /files/system_files/kernel

# Base Image
FROM ghcr.io/projectbluefin/dakota:latest

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/system_files/kernel/setup-kernel.sh
    
RUN bootc container lint
```
