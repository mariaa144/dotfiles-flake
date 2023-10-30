#!/run/current-system/sw/bin/bash

wipefs -a /dev/disk/by-id/virtio-abcdef0123456789-part{1,2,3,4,5}
wipefs -a /dev/disk/by-id/virtio-abcdef0123456789
zpool labelclear -f /dev/disk/by-id/virtio-abcdef0123456789-part{1,2,3,3,4,5}
zpool labelclear -f /dev/disk/by-id/virtio-abcdef0123456789
sgdisk --zap-all /dev/disk/by-id/virtio-abcdef0123456789
