#!/bin/bash

# as root, requires libcgroup-tools

cgcreate -g memory:memlimit
cgset -r memory.max=1k memlimit
cgexec -g memory:memlimit ls -al # will be killed


# as ordinary user, only raw files
sudo mkdir /sys/fs/cgroup/testgroup
# set memory limit
echo "1k" | sudo tee /sys/fs/cgroup/testgroup/memory.max
# $$ is shell PID => assign to cgroup, launch new process
sh -c 'echo $$ | sudo tee /sys/fs/cgroup/testgroup/cgroup.procs && exec "$@"' _ id -u

echo "1000k" | sudo tee /sys/fs/cgroup/testgroup/memory.max
# now it works
sh -c 'echo $$ | sudo tee /sys/fs/cgroup/testgroup/cgroup.procs && exec "$@"' _ id -u

# freezing is fun, but you need two terminals
sh -c 'echo $$; counter=0; while true; do echo "$count"; count=$((count + 1)); sleep 1; done;'
# that prints a PID at first, insert into the next command:
echo "${PID_OF_COUNTER}" | sudo tee /sys/fs/cgroup/testgroup/cgroup.procs
# counter freezes
echo "1" | sudo tee /sys/fs/cgroup/testgroup/cgroup.freeze
# take a look at stats:
cat /sys/fs/cgroup/testgroup/memory.current


# and with systemd

systemd-run --user --scope --unit=test-unit bash

systemctl --user freeze test-unit.scope

# restart:
systemctl --user thaw test-unit.scope

You can also apply resource limits:
systemctl --user set-property --runtime test-unit.scope MemoryMax=100M
