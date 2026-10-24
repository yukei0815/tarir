{
  lib,
  stdenv,
  cmake,
  ninja,
  sdl3,
  boost,
  catch2_3,
  cpp-jwt,
  cubeb,
  enet,
  fetchFromGitea,
  fetchFromGitHub,
  fetchurl,
  ffmpeg-headless,
  fmt,
  frozen-containers,
  gamemode,
  glslang,
  httplib,
  kdePackages,
  libopus,
  libusb1,
  llvmPackages,
  lz4,
  nlohmann_json,
  oaknut,
  openssl,
  overrideCC,
  pipewire,
  pkg-config,
  python3,
  qt6,
  simpleini,
  sirit,
  spirv-headers,
  stb,
  unordered_dense,
  vulkan-headers,
  vulkan-loader,
  vulkan-memory-allocator,
  vulkan-utility-libraries,
  xbyak,
  zlib,
  zstd,
  callPackage,
  runCommand,
  wrapGAppsHook3,
  useLLVM ? enablePGO,
  enablePGO ? false,
  buildPreset ? "generic",
}:

assert enablePGO -> useLLVM;
assert (
  lib.assertOneOf "eden-nightly buildPreset" buildPreset [
    "generic"
    "v3"
    "zen2"
    "zen4"
    "armv9"
  ]
);

let
  # bintools for PGO
  llvmStdenv = overrideCC llvmPackages.stdenv (
    llvmPackages.stdenv.cc.override { inherit (llvmPackages) bintools; }
  );

  edenStdenv = if useLLVM then llvmStdenv else stdenv;

  pins = lib.importJSON ./pins.json;

  # Use fetchurl to fetch pins and then extract
  # Using fetchzip would mean the hashes can't be reused and would need nix-update to fetch them.what
  fetchPin =
    name:
    runCommand "${name}-source" { } ''
      mkdir $out
      tar xzf ${
        fetchurl {
          url = "https://github.com/${pins.${name}.repo}/archive/${pins.${name}.version}.tar.gz";
          sha512 = pins.${name}.hash;
        }
      } -C $out --strip-components=1
    '';

  # Pinning reshade to the version specified by eden
  # not bothering to apply patch ".patch/reshade/${p}" - irrelevant for linux builds
  reshade = fetchPin "reshade";

  zbic = fetchPin "zbic";

  profdata = fetchurl {
    url = "https://github.com/Eden-CI/PGO/releases/download/${pins.profdata.version}/eden.profdata";
    sha256 = pins.profdata.hash;
  };

  pgoFlags = toString [
    "-fprofile-use=${profdata}"
    "-Wno-backend-plugin"
    "-Wno-profile-instr-unprofiled"
    "-Wno-profile-instr-out-of-date"
  ];

  nx_tzdb = callPackage ./nx_tzdb.nix { };

  # eden broken by latest httplib version bump
  # upstream likely not interested in fixes, actively looking to remove the dependency (https://git.eden-emu.dev/eden-emu/eden/issues/4194)
  # pin httplib for now, hopefully can entirely drop in next eden release
  httplib' = httplib.overrideAttrs (finalAttrs: {
    version = "0.30.2";

    src = fetchFromGitHub {
      owner = "yhirose";
      repo = "cpp-httplib";
      rev = "v${finalAttrs.version}";
      hash = "sha256-psVyn14QHMXG/x9SOOiR7ZBt8dHqa2A/w92WQQDukKM=";
    };
  });
in

edenStdenv.mkDerivation (finalAttrs: {
  pname = "eden-unstable";
  version = "0.2.1-unstable-2026-10-18";

  src = fetchFromGitea {
    domain = "git.eden-emu.dev";
    owner = "eden-emu";
    repo = "eden";
    rev = "de7e6e01d43e8cf2ec193d74fa053b0d7949955f";
    hash = "sha256-VZtRaZ+7EvhuH1bRsw/d4mk3KuFPHHD4PJEUo3Mrxoo=";
  };

  strictDeps = true;
  __structuredAttrs = true;

  nativeBuildInputs = [
    cmake
    ninja
    glslang
    pkg-config
    python3
    qt6.qttools
    qt6.wrapQtAppsHook
    wrapGAppsHook3
  ];

  buildInputs = [
    boost
    cpp-jwt
    cubeb
    enet
    ffmpeg-headless
    fmt
    frozen-containers
    gamemode
    httplib'
    kdePackages.quazip
    libopus
    libusb1
    # intentionally omitted: LLVM - heavy, only used for stack traces in the debugger
    lz4
    nlohmann_json
    openssl
    qt6.qtbase
    qt6.qtmultimedia
    qt6.qtwayland
    qt6.qtwebengine
    qt6.qtcharts
    # intentionally omitted: renderdoc - heavy, developer only
    sdl3
    stb
    simpleini
    spirv-headers
    vulkan-headers
    vulkan-memory-allocator
    vulkan-utility-libraries
    sirit
    unordered_dense
    zlib
    zstd
  ]
  ++ lib.optionals stdenv.hostPlatform.isx86_64 [
    xbyak
  ]
  ++ lib.optionals stdenv.hostPlatform.isAarch64 [
    oaknut
  ];

  doCheck = true;

  checkInputs = [
    catch2_3
    oaknut
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_TESTING" finalAttrs.finalPackage.doCheck)
    (lib.cmakeBool "YUZU_TESTS" false) # some timer tests are flaky

    # use system libraries
    (lib.cmakeBool "CPMUTIL_FORCE_SYSTEM" true)
    (lib.cmakeFeature "YUZU_TZDB_PATH" "${nx_tzdb}")

    # enable some optional features
    (lib.cmakeBool "YUZU_USE_QT_WEB_ENGINE" true)
    (lib.cmakeBool "YUZU_USE_QT_MULTIMEDIA" true)
    (lib.cmakeBool "ENABLE_QT_TRANSLATION" true)
    (lib.cmakeBool "ENABLE_LTO" true)

    # We dont want to bother upstream with potentially outdated compat reports
    (lib.cmakeBool "YUZU_ENABLE_COMPATIBILITY_REPORTING" false)

    (lib.cmakeFeature "TITLE_BAR_FORMAT_IDLE" "${finalAttrs.pname} | ${finalAttrs.version} (nixpkgs) {}")
    (lib.cmakeFeature "TITLE_BAR_FORMAT_RUNNING" "${finalAttrs.pname} | ${finalAttrs.version} (nixpkgs) | {}")

    (lib.cmakeFeature "YUZU_BUILD_PRESET" buildPreset)

    (lib.cmakeBool "reshade_FORCE_BUNDLED" true)
    (lib.cmakeFeature "reshade_CUSTOM_DIR" "${reshade}")

    (lib.cmakeBool "zbic_FORCE_BUNDLED" true)
    (lib.cmakeFeature "zbic_CUSTOM_DIR" "${zbic}")
  ]
  ++ lib.optionals enablePGO [
    (lib.cmakeFeature "CMAKE_C_FLAGS" pgoFlags)
    (lib.cmakeFeature "CMAKE_CXX_FLAGS" pgoFlags)
  ];

  postInstall = ''
    install -Dm444 $src/dist/72-eden-input.rules $out/lib/udev/rules.d/72-eden-input.rules
  '';

  preFixup = ''
    qtWrapperArgs+=(--prefix LD_LIBRARY_PATH : ${
      lib.makeLibraryPath [
        vulkan-loader
        pipewire
      ]
    })
  '';

  passthru = {
    inherit nx_tzdb;

    updateScript = ./update.sh;
  };

  meta = {
    description = "Switch 1 emulator derived from Yuzu and Sudachi";
    homepage = "https://eden-emu.dev/";
    mainProgram = "eden";
    maintainers = [ { name = "yukei"; } ];
    license = with lib.licenses; [
      # Primary
      gpl3Plus

      # Build system
      lgpl3Plus

      # Dynarmic and Yuzu code
      gpl2Plus
      bsd0

      # Icons
      cc-by-40
      cc-by-sa-30
      cc0

      # Vendored/incorporated libs
      asl20
      llvm-exception
      lib.licenses.boost
      bsd2
      bsd3
      mit
      mpl20
      wtfpl
    ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
