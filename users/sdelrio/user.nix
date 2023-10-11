{ config, pkgs, home-manager, ... }:

{
# Define a user account.
  users.users.sdelrio = {
    isNormalUser = true;
    initialPassword = "changeme";
    extraGroups =
      [ "wheel" "networkmanager" "audio" "docker" "nixconfig" "dialout" ];
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILGTsI9Q7a92VGc8QGdTdWxCx1J0W05iYVnkH5Xz4nBm"
      ];
    };
    packages = with pkgs; [
      tree
    ];
  };
}