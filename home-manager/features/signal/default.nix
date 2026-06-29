{ pkgs, ... }:
let
  # Same Wayland/ozone flags the slack feature applies, so Signal renders
  # natively on Wayland (crisp on the 4K @ scale-2 outputs) instead of via
  # XWayland. Unlike slack — which ships an ELF at lib/slack/slack that gets
  # re-wrapped in installPhase — signal-desktop's bin is already a generated
  # Electron launcher that forwards "$@" to electron, so wrapProgram appending
  # the flags in postFixup is the right equivalent.
  signal-desktop = pkgs.signal-desktop.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
    postFixup = (old.postFixup or "") + ''
      wrapProgram $out/bin/signal-desktop \
        --add-flags "--ozone-platform=wayland --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --enable-wayland-ime"
    '';
  });
in
{
  home.packages = [ signal-desktop ];
}
