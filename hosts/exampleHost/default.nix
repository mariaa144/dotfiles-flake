{ inputs, ... }:
let inherit (inputs) nixpkgs;
in {
  zfs-root = {
    boot = {
      devNodes = "/dev/disk/by-id/";
      bootDevices = [ "bootDevices_placeholder" ];
      immutable = false;
      removableEfi = true;
      sshUnlock = {
        # read sshUnlock.txt file.
        enable = false;
        authorizedKeys = [ ];
      };
    };
  };
  boot.initrd.availableKernelModules = [ "kernelModules_placeholder" ];
  boot.kernelParams = [ ];
  networking.hostId = "abcd1234";
  # read changeHostName.txt file.
  networking.hostName = "exampleHost";
  time.timeZone = "Europe/Berlin";

  # import preconfigured profiles
  imports = [
    "${nixpkgs}/nixos/modules/installer/scan/not-detected.nix"
    # "${nixpkgs}/nixos/modules/profiles/hardened.nix"
    # "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
  ];
}
