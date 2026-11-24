{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
  pkg-config,
  zstd,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "tack";
  version = "1.0.1-unstable-2026-11-23";
  src = fetchFromGitHub {
    owner = "manic-systems";
    repo = "tack";
    rev = "35c1c4cb2653226de6bf7744d648549592ad341a";
    hash = "sha256-sHc/kJwHpMcszaBMniAMAp5CiUEIph6pb49pQ6Amag8=";
  };

  __structuredAttrs = true;

  cargoHash = "sha256-LvS59RrgR4/VdO461KlY3+1PgIfNuB7akmqPVg029zs=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ zstd ];

  prePatch = ''
    rm .cargo/config.toml
  '';

  doInstallCheck = true;

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };

  meta = {
    homepage = "https://github.com/manic-systems/tack";
    description = "flake-like toml nix pins, lazily fetched and transformed";
    mainProgram = "tack";
    license = lib.licenses.eupl12;
    maintainers = [
      { name = "yukei"; }
    ];
  };
})
