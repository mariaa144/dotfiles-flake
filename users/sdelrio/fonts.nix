{ fonts, pkgs, ... }: {

  # https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/
  # https://nixos.wiki/wiki/Fonts
  fonts.fonts = with pkgs; [
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
    enableDefaultFonts = true;
    fontconfig = {
      defaultFonts = {
        monospace = [ "FiraCode" ];
      };
    };
  };
}