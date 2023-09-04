# This file defines overlays
{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  customs = _final: prev: {
    # hyprland = inputs.hyprland.packages.${prev.system}.hyprland;
  };
  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # hyprland = prev.hyprland.overrideAttrs (finalAttrs: prevAttrs: {
    #   src = prev.fetchgit {
    #     url = /mnt/data/Resources/Hyprland;
    #     rev = "3d0b1283d2c28264370259606f4a88187faa754e";
    #     sha256 = "62z0oX5RwHSBOtz0viwOR5DA7SEaZVz0ZHSFQiLPgYo=";
    #   };
    # });
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
