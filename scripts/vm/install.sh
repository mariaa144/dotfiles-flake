#!/run/current-system/sw/bin/bash
#!/bin/bash
set -e

# Preparation

DISK='/dev/disk/by-id/virtio-abcdef0123456789'
echo "[info] DISK=${DISK}"

MIRROR=
# If raid, put more disks here and update mirror env var
#MIRROR=mirror

ROOT_ENCRYPT=false
ROOT_ENCRYPT_PASSWORD=changeme

MNT=$(mktemp -d)
#MNT=/tmp/tmp12345

##Set swap size in GB, set to 1 if you don’t want swap to take up too much space
SWAPSIZE=2
echo "[info] SWAPSIZE=${SWAPSIZE}"

## Set how much space should be left at the end of the disk, minimum 1GB
RESERVE=1
echo "[info] RESERVER=${RESERVE}"

## For git commit configs
EMAIL=myuser@users.noreply.github.com
NAME="myuser"

## Git for system configuration
GITREPO=https://github.com/sdelrio/homenix-flake.git
GITBRANCH=wip-vm1
GITSED=false
#MYHOST=vm1-terminal
MYHOST=vm1-cinnamon
# keep git remote, then 'yes'. If want clean and create a new one then 'no'
KEEPGIT=yes

## Enable Nix Flakes functionality
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

## Install programs needed for system installation
for p in git jq partprobe; do
  if ! command -v $p; then nix-env -f '<nixpkgs>' -iA $p; fi
done 

# System Install

echo "[info] Partitioning the disks:"

partition_disk () {
 local disk="${1}"
 blkdiscard -f "${disk}" || true
 echo "${disk} blkdiscarded"

 parted --script --align=optimal "${disk}" -- \
 mklabel gpt \
 mkpart EFI 2MiB 1GiB \
 mkpart bpool 1GiB 5GiB \
 mkpart rpool 5GiB -$((SWAPSIZE + RESERVE))GiB \
 mkpart swap -$((SWAPSIZE + RESERVE))GiB -"${RESERVE}"Gi \
 mkpart BIOS 1MiB 2MiB \
 set 1 esp on \
 set 5 bios_grub on \
 set 5 legacy_boot on

 partprobe "${disk}"
 udevadm settle && echo "[OK] udevadm settle"

 parted ${disk} print
}

partition_disk_noswap () {
 local disk="${1}"
 blkdiscard -f "${disk}" || true
 echo "${disk} blkdiscarded"

 parted --script --align=optimal "${disk}" -- \
 mklabel gpt \
 mkpart EFI 2MiB 1GiB \
 mkpart bpool 1GiB 5GiB \
 mkpart rpool 5GiB -$((SWAPSIZE + RESERVE))GiB \
 mkpart BIOS 1MiB 2MiB \
 set 1 esp on \
 set 4 bios_grub on \
 set 4 legacy_boot on

 partprobe "${disk}"
 udevadm settle && echo "[OK] udevadm settle"

 parted ${disk} print
}

for i in ${DISK}; do
 if [[ "$SWAPSIZE" = "0" ]]; then
   partition_disk_noswap "${i}"
 else
   partition_disk "${i}"
 fi
done
sync

echo "[info] blkid -p ${DISK}-part{1,2,3,4,5} | grep zfs_member | grep --color LABEL"
blkid -p ${DISK}-part{1,2,3,4,5} | grep zfs_member | grep --color LABEL || true
sync

sleep 1

if [[ "$SWAPSIZE" -ne "0" ]]; then
  echo "[info] Setup encrypted swap"
  for i in ${DISK}; do
    cryptsetup open --type plain --key-file /dev/random "${i}"-part4 "${i##*/}"-part4
    mkswap /dev/mapper/"${i##*/}"-part4
    swapon /dev/mapper/"${i##*/}"-part4
  done
fi

echo "[info] creating boot pool"
# -O atime=off not needed is set up later for the nixos/root
# shellcheck disable=SC2046
zpool create \
    -o compatibility=grub2 \
    -o ashift=12 \
    -o autotrim=on \
    -O acltype=posixacl \
    -O canmount=off \
    -O compression=lz4 \
    -O devices=off \
    -O normalization=formD \
    -O relatime=on \
    -O xattr=sa \
    -O mountpoint=/boot \
    -R "${MNT}" \
    bpool \
    ${MIRROR} \
    $(for i in ${DISK}; do
       printf '%s ' "${i}-part2";
      done)

echo "[info] creating root pool"
# shellcheck disable=SC2046
zpool create \
    -o ashift=12 \
    -o autotrim=on \
    -R "${MNT}" \
    -O acltype=posixacl \
    -O canmount=off \
    -O compression=zstd \
    -O dnodesize=auto \
    -O normalization=formD \
    -O relatime=on \
    -O xattr=sa \
    -O mountpoint=/ \
    rpool \
    ${MIRROR} \
    $(for i in ${DISK}; do
      printf '%s ' "${i}-part3";
     done)

echo "[info] created pools:"
zpool list

if [[ "$ROOT_ENCRYPT" = "true" ]]; then
# Encrypted root system container. Note: Change the password
  echo "[info] zfs create root encrypted"
  echo $ROOT_ENCRYPT_PASSWORD | zfs create \
    -o canmount=off \
    -o mountpoint=none \
    -o encryption=on \
    -o keylocation=prompt \
    -o keyformat=passphrase \
  rpool/nixos
else
# Unencrypted root system container
  echo "[info] zfs create root unencrypt"
  zfs create \
    -o canmount=off \
    -o mountpoint=none \
  rpool/nixos
fi

echo "[info] Creating system dataset"
zfs create -o mountpoint=legacy rpool/nixos/root
mount -t zfs rpool/nixos/root "${MNT}"/
zfs create -o mountpoint=legacy rpool/nixos/home
mkdir "${MNT}"/home
mount -t zfs rpool/nixos/home "${MNT}"/home
zfs create -o mountpoint=legacy rpool/nixos/var
zfs create -o mountpoint=legacy rpool/nixos/var/lib
zfs create -o mountpoint=legacy rpool/nixos/var/log
zfs create -o mountpoint=none bpool/nixos
zfs create -o mountpoint=legacy bpool/nixos/root
mkdir "${MNT}"/boot
mount -t zfs bpool/nixos/root "${MNT}"/boot
mkdir -p "${MNT}"/var/log
mkdir -p "${MNT}"/var/lib
mount -t zfs rpool/nixos/var/lib "${MNT}"/var/lib
mount -t zfs rpool/nixos/var/log "${MNT}"/var/log
zfs create -o mountpoint=legacy rpool/nixos/empty
zfs snapshot rpool/nixos/empty@start


echo "[info] Format and mount ESP EFI"
for i in ${DISK}; do
 mkfs.vfat -n EFI "${i}"-part1
 mkdir -p "${MNT}"/boot/efis/"${i##*/}"-part1
 mount -t vfat -o iocharset=iso8859-1 "${i}"-part1 "${MNT}"/boot/efis/"${i##*/}"-part1
done

# System Configuration

mkdir -p "${MNT}"/etc

if [[ "$KEEPGIT" = "yes" ]]; then
  git clone --branch ${GITBRANCH} \
    ${GITREPO} "${MNT}"/etc/nixos
  git -C "${MNT}"/etc/nixos config user.email "${EMAIL}"
  git -C "${MNT}"/etc/nixos config user.name "${NAME}"
else
  git clone --depth 1 --branch ${GITBRANCH} \
    ${GITREPO} "${MNT}"/etc/nixos
  rm -rf "${MNT}"/etc/nixos/.git
  git -C "${MNT}"/etc/nixos/ init -b main
  git -C "${MNT}"/etc/nixos/ add "${MNT}"/etc/nixos/
  git -C "${MNT}"/etc/nixos config user.email "${EMAIL}"
  git -C "${MNT}"/etc/nixos config user.name "${NAME}"
  git -C "${MNT}"/etc/nixos commit -asm 'initial commit'
fi

if [[ "${GITSED}" = "true" ]]; then 
  echo "[info] Customize config to your hardware"

  for i in ${DISK}; do
    sed -i \
    "s|/dev/disk/by-id/|${i%/*}/|" \
    "${MNT}"/etc/nixos/hosts/exampleHost/default.nix
    break
  done

  diskNames=""
  for i in ${DISK}; do
    diskNames="${diskNames} \"${i##*/}\""
  done

  echo "[info] sed bootDevices_placeholder "${MNT}"/etc/nixos/hosts/exampleHost/default.nix"
  sed -i "s|\"bootDevices_placeholder\"|${diskNames}|g" \
    "${MNT}"/etc/nixos/hosts/exampleHost/default.nix

  echo "[info] sed abcd1234 "${MNT}"/etc/nixos/hosts/exampleHost/default.nix"
  sed -i "s|\"abcd1234\"|\"$(head -c4 /dev/urandom | od -A none -t x4| sed 's| ||g' || true)\"|g" \
    "${MNT}"/etc/nixos/hosts/exampleHost/default.nix

  echo "[info] sed x86_64-linux "${MNT}"/etc/nixos/flake.nix"
  sed -i "s|\"x86_64-linux\"|\"$(uname -m || true)-linux\"|g" \
    "${MNT}"/etc/nixos/flake.nix

  echo "[info] Detect kernel modules needed for boot"
  cp "$(command -v nixos-generate-config || true)" ./nixos-generate-config

  chmod a+rw ./nixos-generate-config

  # shellcheck disable=SC2016
  echo 'print STDOUT $initrdAvailableKernelModules' >> ./nixos-generate-config

  kernelModules="$(./nixos-generate-config --show-hardware-config --no-filesystems | tail -n1 || true)"

  echo "[info] kernelModules=$kernelModules"

  sed -i "s|\"kernelModules_placeholder\"|${kernelModules}|g" \
    "${MNT}"/etc/nixos/hosts/exampleHost/default.nix

  echo "[question] Root Password"
  rootPwd=$(mkpasswd -m SHA-512)

  sed -i \
  "s|rootHash_placeholder|${rootPwd}|" \
  "${MNT}"/etc/nixos/configuration.nix

  git -C "${MNT}"/etc/nixos commit -asm 'initial installation'
fi

echo "[info] Update flake lock file to track latest system version"
nix flake update --commit-lock-file \
  "git+file://${MNT}/etc/nixos"

echo "[info] Install system and apply configuration"
nixos-install \
--root "${MNT}" \
--no-root-passwd \
--flake "git+file://${MNT}/etc/nixos#${MYHOST}"

echo "[info] Umount and export pools"
umount -Rl "${MNT}"
zpool export -a
