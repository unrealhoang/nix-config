{
  lib,
  stdenv,
  fetchFromGitHub,
  autoPatchelfHook,
  autoAddDriverRunpath,
  makeWrapper,
  buildNpmPackage,
  cmake,
  avahi,
  libevdev,
  libpulseaudio,
  libxtst,
  libxrandr,
  libxi,
  libxfixes,
  libxdmcp,
  libx11,
  libxcb,
  openssl,
  libopus,
  boost,
  pkg-config,
  libdrm,
  wayland,
  wayland-scanner,
  libffi,
  libcap,
  libgbm,
  curl,
  pcre,
  pcre2,
  python3,
  libuuid,
  libselinux,
  libsepol,
  libthai,
  libdatrie,
  libxkbcommon,
  libepoxy,
  libva,
  libvdpau,
  libglvnd,
  numactl,
  amf-headers,
  svt-av1,
  vulkan-loader,
  libappindicator,
  libnotify,
  miniupnpc,
  nlohmann_json,
  config,
  coreutils,
  udevCheckHook,
  cudaSupport ? config.cudaSupport,
  cudaPackages ? { },
}:
let
  stdenv' = if cudaSupport then cudaPackages.backendStdenv else stdenv;
in
stdenv'.mkDerivation (finalAttrs: {
  pname = "polaris";
  version = "1.0.12";

  src = fetchFromGitHub {
    owner = "papi-ux";
    repo = "polaris";
    tag = "v${finalAttrs.version}";
    hash = "sha256-dELegUmIY4mnBIPw67VvXzA9xQqs/RntY0a2NRUUKZg=";
    fetchSubmodules = true;
  };

  ui = buildNpmPackage {
    inherit (finalAttrs) src version;
    pname = "polaris-ui";
    npmDepsHash = "sha256-2Ih21/vkf47enPLjl+mLn0V9ei67s59elEEcZHIVhf0=";

    preBuild = ''
      export POLARIS_SOURCE_ASSETS_DIR=$PWD/src_assets
      export POLARIS_ASSETS_DIR=$PWD/_vite_out
      mkdir -p "$POLARIS_ASSETS_DIR/assets/web"
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r _vite_out/assets/web "$out"/web
      runHook postInstall
    '';
  };

  postPatch =
    # ship a prebuilt UI; drop the npm-driven web-ui target
    ''
      substituteInPlace cmake/targets/common.cmake \
        --replace-fail 'find_program(NPM npm REQUIRED)' "" \
        --replace-fail 'add_dependencies(polaris web-ui)' ""
    ''
    # strip pkg-config-based discovery of systemd/udev; we pass paths via cmakeFlags
    + ''
      substituteInPlace cmake/packaging/linux.cmake \
        --replace-fail 'find_package(Systemd)' ""
    ''
    # fix hard-coded /bin/sleep in the systemd unit
    + ''
      substituteInPlace packaging/linux/polaris.service.in \
        --replace-fail '/bin/sleep' '${lib.getExe' coreutils "sleep"}'
    '';

  nativeBuildInputs =
    [
      cmake
      pkg-config
      python3
      makeWrapper
      wayland-scanner
      autoPatchelfHook
    ]
    ++ lib.optionals cudaSupport [
      autoAddDriverRunpath
      cudaPackages.cuda_nvcc
      (lib.getDev cudaPackages.cuda_cudart)
    ];

  buildInputs =
    [
      avahi
      amf-headers
      boost
      curl
      libappindicator
      libcap
      libdatrie
      libdrm
      libepoxy
      libevdev
      libffi
      libgbm
      libnotify
      libopus
      libpulseaudio
      libselinux
      libsepol
      libthai
      libuuid
      libva
      libvdpau
      libx11
      libxcb
      libxdmcp
      libxfixes
      libxi
      libxkbcommon
      libxrandr
      libxtst
      miniupnpc
      nlohmann_json
      numactl
      openssl
      pcre
      pcre2
      svt-av1
      wayland
    ]
    ++ lib.optionals cudaSupport [
      cudaPackages.cudatoolkit
      cudaPackages.cuda_cudart
    ];

  runtimeDependencies = [
    avahi
    libgbm
    libglvnd
    libxcb
    libxrandr
  ];

  cmakeFlags =
    [
      "-Wno-dev"
      (lib.cmakeBool "BOOST_USE_STATIC" false)
      (lib.cmakeBool "BUILD_DOCS" false)
      (lib.cmakeFeature "POLARIS_PUBLISHER_NAME" "nixpkgs")
      (lib.cmakeFeature "POLARIS_PUBLISHER_WEBSITE" "https://github.com/papi-ux/polaris")
      (lib.cmakeFeature "POLARIS_PUBLISHER_ISSUE_URL" "https://github.com/papi-ux/polaris/issues")
      (lib.cmakeFeature "POLARIS_DESKTOP_ICON" "polaris")
      (lib.cmakeFeature "POLARIS_EXECUTABLE_PATH" "${placeholder "out"}/bin/polaris")
      # upstream finds these via pkg-config in FHS; we provide paths directly
      (lib.cmakeBool "UDEV_FOUND" true)
      (lib.cmakeBool "SYSTEMD_FOUND" true)
      (lib.cmakeFeature "UDEV_RULES_INSTALL_DIR" "lib/udev/rules.d")
      (lib.cmakeFeature "SYSTEMD_USER_UNIT_INSTALL_DIR" "lib/systemd/user")
      (lib.cmakeFeature "SYSTEMD_MODULES_LOAD_DIR" "lib/modules-load.d")
    ]
    ++ lib.optionals (!cudaSupport) [
      (lib.cmakeBool "POLARIS_ENABLE_CUDA" false)
    ];

  env = {
    BUILD_VERSION = finalAttrs.version;
    BRANCH = "master";
    COMMIT = "";
  };

  # place the prebuilt UI where the install() rule will pick it up
  preBuild = ''
    mkdir -p assets
    cp -r ${finalAttrs.ui}/web assets/web
  '';

  buildFlags = [ "polaris" ];

  installPhase = ''
    runHook preInstall
    cmake --install .
    runHook postInstall
  '';

  # expose udev rules and modules-load.d snippet at the paths NixOS scans
  postInstall = ''
    install -Dm644 $out/assets/udev/rules.d/60-polaris.rules \
      $out/lib/udev/rules.d/60-polaris.rules
    install -Dm644 $out/assets/modules-load.d/60-polaris.conf \
      $out/lib/modules-load.d/60-polaris.conf
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ udevCheckHook ];

  postFixup = lib.optionalString cudaSupport ''
    wrapProgram $out/bin/polaris \
      --set LD_LIBRARY_PATH ${lib.makeLibraryPath [ vulkan-loader ]}
  '';

  meta = {
    description = "Self-hosted GameStream host for Moonlight/Nova (Sunshine/Apollo fork)";
    homepage = "https://github.com/papi-ux/polaris";
    license = lib.licenses.gpl3Only;
    mainProgram = "polaris";
    platforms = lib.platforms.linux;
  };
})
