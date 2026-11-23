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
  version = "1.0.1-unstable-2026-11-22";
  src = fetchFromGitHub {
    owner = "manic-systems";
    repo = "tack";
    rev = "a992d76e8e9c906a3714b596ba3a9b8386a817d6";
    hash = "sha256-u6gAZW/m9HnyiI/QpupurIB0L3SRUsBDRvrCrJp5EMU=";
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
