# #
##
##  per-host configuration for exampleHost
##
##

{ system, pkgs, ... }: {
  inherit pkgs system;
  zfs-root = {
    boot = {
      devNodes = "/dev/disk/by-id/";
      bootDevices = [ "bootDevices_placeholder" ];
      immutable = false;
      availableKernelModules = [
        # for booting virtual machine
        # with virtio disk controller
        "virtio_pci"
        "virtio_blk"
        # for sata drive
        "ahci"
        # for nvme drive
        "nvme"
        # for external usb drive
        "uas"
      ];
      removableEfi = true;
      kernelParams = [ ];
      sshUnlock = {
        # read sshUnlock.txt file.
        enable = false;
        authorizedKeys = [ ];
      };
    };
    networking = {
      # read changeHostName.txt file.
      hostName = "exampleHost";
      timeZone = "Europe/Berlin";
      hostId = "abcd1234";
    };
    users = {
      root = {
        initialHashedPassword = "rootHash_placeholder";
        authorizedKeys = [ "sshKey_placeholder" ];
        isSystemUser = true;
      };

      # "normalUser" is the user name,
      # change if needed.
      normalUser = {
        # Generate hashed password with "mkpasswd" command,
        # "!" disables login.
        initialHashedPassword = "!";
        description = "Full Name";
        # Users in "wheel" group are allowed to use "doas" command
        # to obtain root permissions.
        extraGroups = [ "wheel" ];
        packages = builtins.attrValues {
          inherit (pkgs)
            mg # emacs-like editor
            jq # other programs
          ;
        };
        isNormalUser = true;
      };
    };
  };
}
