#!/bin/bash

# prerequisite
gcc -lseccomp -O2 -Wall -Werror -Wextra -o seccomp-run.out seccomp-run.c

KEY_ID="$(keyctl add user container-demo 'SUPER_SECRET_DEMO_TOKEN' @s)"

keyctl print "$KEY_ID"

# all of these fail
./seccomp-run.out keyctl show
./seccomp-run.out keyctl print "$KEY_ID"
./seccomp-run.out keyctl revoke "$KEY_ID"

keyctl revoke "$KEY_ID"
keyctl unlink "$KEY_ID"
