{
  lib,
  dbus,
  eudev,
  fetchFromGitHub,
  installShellFiles,
  libdisplay-info_0_3,
  libglvnd,
  libinput,
  libxkbcommon,
  libgbm,
  versionCheckHook,
  nix-update-script,
  pango,
  pipewire,
  pkg-config,
  rustPlatform,
  seatd,
  stdenv,
  systemdLibs,
  wayland,
  withDbus ? true,
  withDinit ? false,
  withScreencastSupport ? true,
  withSystemd ? true,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "niri-urayde";
  version = "26.04-unstable-2026-10-21";

  src = fetchFromGitHub {
    owner = "urayde";
    repo = "niri";
    rev = "e9804c1cc9cd29faa7c58804240d72db7712cd94";
    hash = "sha256-cFWPiGWgFDkJLbr+/Vq+DiAqvLBIoVsAMOfPTbJ3GoI=";
  };

  outputs = [
    "out"
    "doc"
  ];

  postPatch = ''
    patchShebangs resources/niri-session
    substituteInPlace resources/niri.service \
      --replace-fail 'niri' "$out/bin/niri"
  '';

  cargoHash = "sha256-te42mM+h+TzWovc5WP7KVmFzykBLAirWaKP2oZii5K0=";

  nativeBuildInputs = [
    installShellFiles
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    libdisplay-info_0_3
    libglvnd # For libEGL
    libinput
    libxkbcommon
    libgbm
    pango
    seatd
    wayland # For libwayland-client
  ]
  ++ lib.optional (withDbus || withScreencastSupport || withSystemd) dbus
  ++ lib.optional withScreencastSupport pipewire
  ++ lib.optional withSystemd systemdLibs # Includes libudev
  ++ lib.optional (!withSystemd) eudev; # Use an alternative libudev implementation when building w/o systemd

  buildFeatures =
    lib.optional withDbus "dbus"
    ++ lib.optional withDinit "dinit"
    ++ lib.optional withScreencastSupport "xdp-gnome-screencast"
    ++ lib.optional withSystemd "systemd";
  buildNoDefaultFeatures = true;

  postInstall = ''
    install -Dm0644 README.md resources/default-config.kdl -t $doc/share/doc/niri
    mv docs/wiki $doc/share/doc/niri/wiki

    install -Dm0644 resources/niri.desktop -t $out/share/wayland-sessions
  ''
  + lib.optionalString withDbus ''
    install -Dm0644 resources/niri-portals.conf -t $out/share/xdg-desktop-portal
  ''
  + lib.optionalString (withSystemd || withDinit) ''
    install -Dm0755 resources/niri-session -t $out/bin
  ''
  + lib.optionalString withSystemd ''
    install -Dm0644 resources/niri{-shutdown.target,.service} -t $out/lib/systemd/user
  ''
  + lib.optionalString withDinit ''
    install -Dm0644 resources/dinit/niri{-shutdown,} -t $out/lib/dinit.d/user
  ''
  + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd niri \
      --bash <($out/bin/niri completions bash) \
      --fish <($out/bin/niri completions fish) \
      --nushell <($out/bin/niri completions nushell) \
      --zsh <($out/bin/niri completions zsh)
  '';

  env = {
    # Force linking with libEGL and libwayland-client
    # so they can be discovered by `dlopen()`
    RUSTFLAGS = toString (
      map (arg: "-C link-arg=" + arg) [
        "-Wl,--push-state,--no-as-needed"
        "-lEGL"
        "-lwayland-client"
        "-Wl,--pop-state"
      ]
    );

    # Upstream recommends setting the commit hash manually when in a
    # build environment where the Git repository is unavailable.
    # See https://github.com/niri-wm/niri/wiki/Packaging-niri#version-string
    NIRI_BUILD_COMMIT = "urayde-tarir-${finalAttrs.src.rev}";
  };

  checkFlags = [ "--skip=::egl" ];
  nativeInstallCheckInputs = [ versionCheckHook ];
  preVersionCheck = "version=${lib.head (lib.splitString "-" finalAttrs.version)}";
  doInstallCheck = true;

  passthru = {
    providedSessions = [ "niri" ];
    updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
  };

  meta = {
    description = "Scrollable-tiling Wayland compositor";
    homepage = "https://github.com/urayde/niri";
    changelog = "https://github.com/urayde/niri/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl3Only;
    maintainers = [
      { name = "yukei"; }
    ];
    mainProgram = "niri";
    platforms = lib.platforms.linux;
  };
})
