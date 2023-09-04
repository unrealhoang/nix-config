# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs ? (import ../nixpkgs.nix) { } }: {
  # example = pkgs.callPackage ./example { };
  archcraft-font = pkgs.callPackage ./archcraft-font { };
  fcitx5-bamboo = pkgs.callPackage ./fcitx5-bamboo { };
}
