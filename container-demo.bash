#!/usr/bin/bash

# Teaching demo: run as root on Linux with Podman and util-linux installed.
# Security hardening and network isolation are deliberately omitted.
set -euo pipefail

if (( EUID != 0 )); then
    echo "Run with: sudo bash $0" >&2
    exit 1
fi

image=registry.opensuse.org/opensuse/tumbleweed
demo=$(mktemp -d /var/tmp/container-demo.XXXXXX)
echo "Demo directory: $demo"
pushd "$demo"
mkdir lower upper work merged

# Export a flattened rootfs; the temporary Podman container is never started.
podman pull "$image"
cid=$(podman create "$image" /bin/sh)
trap 'podman rm "$cid" >/dev/null' EXIT
podman export "$cid" | tar --numeric-owner -xpf - -C lower
podman rm "$cid" >/dev/null
trap - EXIT

# Seed two files before treating this directory as our image filesystem.
mkdir -p lower/demo lower/proc
echo 'Hello from the image' > lower/demo/message
echo 'This file belongs to the image' > lower/demo/delete-me

# try this:
# echo $$
# ps -ef
# cat /demo/message
# echo 'Changed inside the container' > /demo/message
# echo 'A new file' > /demo/new-file
# rm /demo/delete-me
# ls -l /demo
# exit

# All mounts below live in a private mount namespace.
status=0
unshare --mount --propagation private --pid --fork bash -ceu '
    cd "$1"
    mount -t overlay overlay \
        -o "lowerdir=$PWD/lower,upperdir=$PWD/upper,workdir=$PWD/work" \
        merged
    mount -t proc proc merged/proc
    export HOME=/root PATH=/usr/sbin:/usr/bin:/sbin:/bin
    export PS1="container# "
    exec chroot merged /bin/sh -i
' bash "$demo" || status=$?

exit "$status"
