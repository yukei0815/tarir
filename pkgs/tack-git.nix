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
  version = "1.0.1-unstable-2026-11-19";
  src = fetchFromGitHub {
    owner = "manic-systems";
    repo = "tack";
    rev = "1424edc27b6e6f6d4f216410e0a2cc1419d96cb7";
    hash = "sha256-z7m16oDAtHsgbBX6gadOpa6pGPXNEahjwyzPC0pbLvM=";
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
