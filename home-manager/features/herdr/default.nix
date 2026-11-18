{ inputs, pkgs, ... }: {
  home.packages = [
    inputs.herdr-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  home.file.".config/herdr/config.toml".text = ''
    onboarding = false

    [keys]
    prefix = "ctrl+j"
  '';
}
