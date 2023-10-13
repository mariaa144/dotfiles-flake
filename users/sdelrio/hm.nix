{ config, pkgs, home-manager, ... }:

{
  home.packages = with pkgs; [
    keybase-gui
    # fd is an unnamed dependency of fzf
    fd
    shell-genie
  ];
  home.stateVersion = "23.05";

  programs.git = {
    enable = true;
    userName = "sdelrio";
    userEmail = "sdelrio@users.noreply.github.com";
  };

}
