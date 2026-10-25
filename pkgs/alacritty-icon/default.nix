# Alacritty rebundled with the custom icon from resources/Alacritty.icns.
{ stdenvNoCC, alacritty }:

stdenvNoCC.mkDerivation {
  pname = "alacritty-icon";
  inherit (alacritty) version meta;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    cp -R ${alacritty} $out
    chmod -R u+w $out
    cp ${../../resources/Alacritty.icns} \
      $out/Applications/Alacritty.app/Contents/Resources/alacritty.icns

    runHook postInstall
  '';
}
