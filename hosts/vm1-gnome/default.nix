# configuration in this file only applies to exampleHost host.

{ pkgs, ... }: {
  programs.tmux = {
    enable = true;
    newSession = true;
    terminal = "tmux-direct";
  };
  services.emacs.enable = false;

  i18n.defaultLocale = "es_ES.UTF-8";

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  console = pkgs.lib.mkForce {
    keyMap = "es";
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

}