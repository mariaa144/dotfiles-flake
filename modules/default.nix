{ config, lib, pkgs, ... }: {
  imports = [ ./boot ./users ./fileSystems ./networking ];
}
