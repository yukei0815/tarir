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
  version = "2.0.0-unstable-2026-11-27";
  src = fetchFromGitHub {
    owner = "manic-systems";
    repo = "tack";
    rev = "673997981720feebb3870645932b6cfe6657db9f";
    hash = "sha256-iRVnAKvQh5vC76QppovlxTklJf98EA+GYEY91loasy4=";
  };

  __structuredAttrs = true;

  cargoHash = "sha256-J0U1vSjiqMMFhSJTJlOmV/9BY8Bzc/ijG2HRcgSqm+w=";

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
