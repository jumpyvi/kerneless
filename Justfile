kernel NAME:
    #!/usr/bin/env bash
    sudo podman build -t {{NAME}}-kernel -f ./kernels/{{NAME}}-kernel.dockerfile . --security-opt label=type:unconfined_t

alpine: (kernel "alpine")
bazzite: (kernel "bazzite")
cachy: (kernel "cachy")
centos: (kernel "centos")
ubuntu: (kernel "ubuntu")
xanmod: (kernel "xanmod")