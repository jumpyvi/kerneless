kernel NAME:
    #!/usr/bin/env bash
    sudo podman build -t {{NAME}}-kernel -f ./kernels/{{NAME}}-kernel.dockerfile . --security-opt label=type:unconfined_t

bazzite: (kernel "bazzite")
cachy: (kernel "cachy")
ubuntu: (kernel "ubuntu")
xanmod: (kernel "xanmod")
surface: (kernel "surface")