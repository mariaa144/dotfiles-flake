# configuration in this file only applies to exampleHost host
#
# only zfs-root.* options can be defined in this file.
#
# all others goes to `configuration.nix` under the same directory as
# this file.

{ config, pkgs, lib, inputs, modulesPath, ... }: {

  programs.tmux = {
    enable = true;
    newSession = true;
    terminal = "tmux-direct";
  };
  services.emacs.enable = false;
  i18n.defaultLocale = "es_ES.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_ES.UTF-8";
    LC_IDENTIFICATION = "es_ES.UTF-8";
    LC_MEASUREMENT = "es_ES.UTF-8";
    LC_MONETARY = "es_ES.UTF-8";
    LC_NAME = "es_ES.UTF-8";
    LC_NUMERIC = "es_ES.UTF-8";
    LC_PAPER = "es_ES.UTF-8";
    LC_TELEPHONE = "es_ES.UTF-8";
    LC_TIME = "es_ES.UTF-8";
  };
  services.xserver = {
    enable = true;
    desktopManager.cinnamon.enable = true;
    displayManager.lightdm.enable = true;
    layout = "es";
  };

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
  console = pkgs.lib.mkForce {
    keyMap = "es";
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = false;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  zfs-root = {
    boot = {
      devNodes = "/dev/disk/by-id/";
      bootDevices = [ "nvme-eui.0000000623011999caf25b02b0000150" ];

      immutable.enable = false;
      removableEfi = true;
      luks.enable = false;
    };
  };

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" ];
  boot.kernelParams = [ "nohibernate" "mitigations=off" ];

  networking = {
    # read changeHostName.txt file.
    hostName = "nexus";
    # head -c4 /dev/urandom | od -A none -t x4
    hostId = "8b5c63d7";

    interfaces = {
      enp7s0.mtu = 9000;
      enp6s0 = {
        useDHCP = false;
        mtu = 9000;
        ipv4.addresses = [{
          address = "192.168.2.58";
          prefixLength = 24;
        }];
      };
    };
  };
  time.timeZone = "Europe/Madrid";

  # import preconfigured profiles
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    # (modulesPath + "/profiles/hardened.nix")
    ../../users/sdelrio/user.nix
    ../../users/sdelrio/fonts.nix
  ];

  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  users.users.sdelrio.extraGroups = [ "docker" "libvirtd" ];

  environment.systemPackages = with pkgs; [
    bitwarden
    brave
    # for samba mounts
    cifs-utils
    corectrl
    firefox
    ## Keyboard-driven layer for GNOME Shell
    # gnomeExtensions.pop-shell
    gpa
    lutris
    lm_sensors
    lshw
    onlyoffice-bin_latest
    pciutils
    plex-media-player
    syncthing
    syncthing-tray
    solaar
    telegram-desktop
    terminator
    # steam
    virt-manager
    vscode
    zsh
    hwloc
  ];

  environment.variables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
    #TERMINAL = "kitty";
  };

}
