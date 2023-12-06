{ fonts, pkgs, ... }: {

  # https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/
  # https://nixos.wiki/wiki/Fonts
  fonts.packages = with pkgs; [
    (nerdfonts.override {
      fonts = [
        "FiraCode"
        "DroidSansMono"
#       "DejaVuSansMono"
#       "SourceCodePro"
      ];
    })
  ];

  fonts = {
    enableDefaultPackages = true;
    fontconfig = {
      defaultFonts = {
        monospace = [ "FiraCode" ];
      };
    };
  };
}
