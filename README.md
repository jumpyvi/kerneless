# Pre-built kernels as OCI containers
> [!WARNING]
This is experimental 🦖! Only run in a test VM!

Run custom kernels on GnomeOS/FreeDesktopSDK based images!

Kernels are updated every two week, images are updated weekly

This repo includes snippets of code from the [UBlue image template](https://github.com/ublue-os/image-template), licensed under Apache 2.0

## Available kernels & images:

### Ubuntu LTS
The latest LTS Ubuntu kernel, tested and relied upon by thousand of users.

>Right now this is on the pre-release of Resolute Racoon, it will follow the current LTS release when Resolute is released.

https://ubuntu.com/kernel


- Kernel OCI package : `ghcr.io/jumpyvi/kerneless:ubuntu`

- Dakota bootable image : `ghcr.io/jumpyvi/kerneless-ubuntu:latest`


----------

### Bazzite rolling kernel

The latest Bazzite kernel, used in the popular Bazzite operating system. Optimized for gaming devices.

https://github.com/bazzite-org/kernel-bazzite

- Kernel OCI package : `ghcr.io/jumpyvi/kerneless:bazzite`

- Dakota bootable image : `ghcr.io/jumpyvi/kerneless-bazzite:latest`

------

### Surface Rolling
> 🧪 Works in qemu, not tested on a real Surface

The latest Surface kernel for GitHub, includes patches for Microsoft Surfaces.
Does not support arm or nvidia

https://github.com/linux-surface/linux-surface

Follows the latest surface kernel available on GitHub for Arch

- Kernel OCI package : `ghcr.io/jumpyvi/kerneless:surface`

- Dakota bootable image : `ghcr.io/jumpyvi/kerneless-surface:latest`

---

### Cachy LTS

The latest LTS CachyOS kernel, designed for improved performance.
No utils, just the kernel, modules and headers

https://github.com/CachyOS/linux-cachyos

- Kernel OCI package : `ghcr.io/jumpyvi/kerneless:cachy`

- Dakota bootable image : `Not planned`

-----

### XanMod LTS (v3)

The LTS XanMod kernel, built to provide a stable, smooth and solid system experience.
Notably Includes `sched_ext` and `binder_linux`

https://xanmod.org/

Follows the latest LTS XanMod kernel available on Ubuntu LTS

- Kernel OCI package : `comming soon...`

- Dakota bootable image : `Not planned`

---

Experimentals kernels from [Alpine](kernels/experimentals/alpine-kernel.dockerfile) and [Centos](kernels/experimentals/WIP.centos-kernel.dockerfile) are also available, but are not maintained, have severe issues and need to be built from source.

None of these kernels are what you want? Feel free to open an issue, or send a PR!

---

## Setup

### (Option 1) Bootc switch to pre-built images
> This option is only available for Ubuntu, Surface and Bazzite

1. Install Dakota on your system
2. `sudo bootc switch ghcr.io/jumpyvi/kerneless-{kernel-name}:latest`

### (Option 2) Add the kernel to your own image

1. Fetch the kernel, either:
   1. Pull the build at `ghcr.io/jumpyvi/kerneless:{kernel-name}`
   2. Generate it locally with `just --choose`


1. Near the top of the Containerfile, in scratch
```
COPY --from=ghcr.io/jumpyvi/kerneless-{kernel-name}:latest /system_files/kernel /files/system_files/kernel
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
COPY --from=ghcr.io/jumpyvi/kerneless:cachy /system_files/kernel /files/system_files/kernel

# Base Image
FROM ghcr.io/projectbluefin/dakota:latest

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    build.sh && \
    /ctx/files/system_files/kernel/setup-kernel.sh
    
RUN bootc container lint
```
