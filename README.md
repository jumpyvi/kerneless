# Pre-built kernels as OCI containers
> [!WARNING]
This is experimental 🦖! Only run in a test VM!

Run custom kernels on ProjectBluefin's Dakota based images!

(Silverblue 43+ support might comme soon)

Feel free to use the code in this repo in any ways you wish

## Available kernels:

### Ubuntu LTS
> Status: Boot, no zram, still usable

The latest LTS Ubuntu kernel.

https://ubuntu.com/kernel

Right now this is on the pre-release of Resolute Racoon, it will follow the current LTS release when Resolute is released.

Zram does not work right now, add `systemd.zram=0` to systemd-boot for now.

----------

### Bazzite GitHub rolling kernel
> Works

The rolling Bazzite kernel

https://github.com/bazzite-org/kernel-bazzite

Follows the latest released kernel in their GitHub

------

### Cachy LTS
> Status: Works, sometime crashes on user setup, still usable </br>
> Not completed, hardcoded on 6.12.66-2 for now

The latest LTS CachyOS kernel.

https://github.com/CachyOS/linux-cachyos

Follows the latest LTS CachyOS kernel avaible in their repos

It does not come with any of the Cachy services, tools or utils, just the barebone kernel.

-----

### Surface Rolling
> Status: Works in VM, not tested on surface

The latest Surface kernel for GitHub

https://github.com/linux-surface/linux-surface

Follows the latest surface kernel available on GitHub for Arch

---

### XanMod LTS (v3)
> Status: Works

The LTS XanMod kernel.

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
