{ stdenv, lib, fetchFromGitHub }:
let
  # Replace these values with the appropriate GitHub repository information
  owner = "archcraft-os";
  repo = "archcraft-packages";
  rev = "501a1f62691f507f4b141b1228ec4d56fb785db3";
in stdenv.mkDerivation {
  name = "archcraft-font";
  src = fetchFromGitHub {
    owner = "archcraft-os";
    repo = "archcraft-packages";
    rev = "501a1f62691f507f4b141b1228ec4d56fb785db3";
    sha256 = "Eat7b59J2MIgwsGcM9Vc3DR62o+0VHQPnOR/1DpefRQ=";
  };

  # Assuming the font file is located inside a "fonts" directory within the repository
  installPhase = ''
    install -Dm644 $src/archcraft-fonts/files/icon-fonts/archcraft.ttf $out/share/fonts/archcraft.ttf
  '';

  meta = with lib; {
    description = "Archcraft font from GitHub";
    license = licenses.gpl3; # Replace with the appropriate license
  };
}
