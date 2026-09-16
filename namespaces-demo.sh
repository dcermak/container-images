#!/bin/bash



# user NS
unshare --user --map-root-user /bin/bash
id
# see that we're "root"
# without --map-root-user, we'll be nobody


# mount NS
sudo unshare --mount /bin/bash
mkdir /mnt/foobar
mount --bind /etc/ /mnt/foobar/
findmnt
# in a different terminal: findmnt too => not found!

# pid NS
sudo unshare --pid --fork --mount-proc /bin/bash
ps aux
# see only two processes


# net NS

# let's add macvlan to connect
ip link add mac0 link eth0 type macvlan mode bridge

sudo unshare --net /bin/bash
ip addr # just loopback
echo $$

# on root shell again:
ip link set dev mac0 netns "${PID_IN_NS}"

# in NS:
ip addr add 192.168.1.194/24 dev mac0 # or whatever IP is on the host
ip route add default via 192.168.1.1 dev mac0
ping 8.8.8.8 # suddenly works
# but beware, you fsck your own networking now 🤦


# ipc
# kinda boring but whatever, first get all IPC instances:
ipcs -a

sudo unshare --ipc
ipcmk -M 1024M # create a shared memory segment
ipcs -a # repeat outside, it's not there


# uts
hostname
sudo unshare --uts
hostname
hostname foobar
hostname # and run it outside too


# cgroup
cat /proc/self/cgroup
sudo unshare --cgroup
cat /proc/self/cgroup
