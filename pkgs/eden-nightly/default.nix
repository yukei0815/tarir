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
  fetchurl,
  ffmpeg-headless,
  fmt,
  frozen-containers,
  gamemode,
  glslang,
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
  yyjson,
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
  # bintools for LTO
  llvmStdenv = overrideCC llvmPackages.stdenv (
    llvmPackages.stdenv.cc.override { inherit (llvmPackages) bintools; }
  );

  edenStdenv = if useLLVM then llvmStdenv else stdenv;

  pins = lib.importJSON ./pins.json;

  # Use fetchurl to fetch pins and then extract
  # Using fetchzip would mean the hashes can't be reused and would need nix-update to fetch them.
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

  # Pin inputs to the version specified by eden
  reshade = fetchPin "reshade"; # not bothering to apply patch ".patch/reshade/${p}" - irrelevant for linux builds
  zbic = fetchPin "zbic";
  jacinth = fetchPin "jacinth"; # C++20 module
  hydrocarbon = fetchPin "hydrocarbon";
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
in

edenStdenv.mkDerivation (finalAttrs: {
  pname = "eden-unstable";
  version = "0.2.1-unstable-2026-11-09";

  src = fetchFromGitea {
    domain = "git.eden-emu.dev";
    owner = "eden-emu";
    repo = "eden";
    rev = "6a767ac43a089fe988526bf7f8477ccc43277fb1";
    hash = "sha256-YmXvuEuHL8FLozlAVWOAwDurPBSkE9xxDiGtsHp3or4=";
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
  ]
  ++ lib.optionals useLLVM [
    # clang-scan-deps wrapper is needed to find C++20 modules
    llvmPackages.clang-tools
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
    kdePackages.quazip
    libopus
    libusb1
    # intentionally omitted: LLVM - heavy, only used for stack traces in the debugger
    lz4
    nlohmann_json # for cpp-jwt
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
    yyjson
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

    (lib.cmakeBool "jacinth_FORCE_BUNDLED" true)
    (lib.cmakeFeature "jacinth_CUSTOM_DIR" "${jacinth}")
    (lib.cmakeBool "JACINTH_USE_SYSTEM_PFR" true)
    (lib.cmakeBool "JACINTH_USE_SYSTEM_YYJSON" true)

    (lib.cmakeBool "hydrocarbon_FORCE_BUNDLED" true)
    (lib.cmakeFeature "hydrocarbon_CUSTOM_DIR" "${hydrocarbon}")
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
