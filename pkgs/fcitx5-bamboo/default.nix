{ lib, stdenv, fetchFromGitHub, cmake, extra-cmake-modules, fcitx5, go, gettext
}:
stdenv.mkDerivation rec {
  pname = "fcitx5-bamboo";
  version = "1.0.4";
  src = fetchFromGitHub {
    owner = "fcitx";
    repo = "fcitx5-bamboo";
    rev = version;
    fetchSubmodules = true;
    sha256 = "EcpuZN2JU6HSuiQgBPBsoYftdHypiyFlrUxDBlVW6eo=";
  };

  preBuild = ''
    HOME=$TMPDIR
  '';
  nativeBuildInputs = [ cmake extra-cmake-modules go ];

  buildInputs = [ fcitx5 gettext ];

  meta = with lib; {
    description = "Bamboo engine support for Fcitx5";
    homepage = "https://github.com/fcitx/fcitx5-bamboo";
    license = licenses.gpl2Plus;
    maintainers = [ "unrealhoang" ];
    platforms = platforms.linux;
  };
}
