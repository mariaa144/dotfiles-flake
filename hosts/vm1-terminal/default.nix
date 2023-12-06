# configuration in this file only applies to exampleHost host
#
# only zfs-root.* options can be defined in this file.
#
# all others goes to `configuration.nix` under the same directory as
# this file.

{ config, pkgs, lib, inputs, modulesPath, ... }: {

  zfs-root = {
    boot = {
      devNodes = "/dev/disk/by-id/";
      bootDevices = [ "virtio-abcdef0123456789" ];
      immutable.enable = false;
      removableEfi = true;
      luks.enable = false;
    };
  };

  boot = {
    initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
    kernelParams = [ "nohibernate" "mitigations=off" ];
  };

  networking = {
    hostName = "vm1-terminal";
    hostId = "53bb851e";
  };

  time.timeZone = "Europe/Madrid";

  # imports preconfigured profiles
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    # (modulesPath + "/profiles/hardened.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    "../../users/sdelrio/user.nix"
  ];
}
