#!/bin/bash
# Security hardening and network isolation are deliberately omitted.
set -euo pipefail

image=registry.opensuse.org/opensuse/tumbleweed
demo=$(mktemp -d /var/tmp/container-demo.XXXXXX)
echo "Demo directory: $demo"
pushd "$demo"
mkdir lower upper work merged

# Export a flattened rootfs; the temporary Podman container is never started.
podman pull "$image"
cid=$(podman create "$image" /bin/sh)
trap 'podman rm "$cid" >/dev/null' EXIT
# Flatten ownership to our UID/GID: all files appear root-owned in the namespace.
# Skip /dev contents so extraction never needs to create device nodes.
podman export "$cid" | tar --no-same-owner -xpf - -C lower \
    --exclude='dev/*' --exclude='./dev/*'
podman rm "$cid" >/dev/null
trap - EXIT

# Seed two files before treating this directory as our image filesystem.
mkdir -p lower/demo lower/proc
echo 'Hello from the image' > lower/demo/message
echo 'This file belongs to the image' > lower/demo/delete-me

# id
# cat /proc/self/uid_map
# echo $$
# ps -ef
# cat /demo/message
# echo 'Changed inside the container' > /demo/message
# echo 'A new file' > /demo/new-file
# rm /demo/delete-me
# ls -l /demo
# exit

status=0
unshare --user --map-root-user \
    --mount --propagation private --pid --fork bash -ceu '
    cd "$1"
    mount -t overlay overlay \
        -o "userxattr,lowerdir=$PWD/lower,upperdir=$PWD/upper,workdir=$PWD/work" \
        merged
    mount -t proc proc merged/proc
    export HOME=/root PATH=/usr/sbin:/usr/bin:/sbin:/bin
    export PS1="container# "
    exec chroot merged /bin/sh -i
' bash "$demo" || status=$?

popd
exit "$status"
