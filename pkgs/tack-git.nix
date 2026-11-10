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
  version = "1.0.1-unstable-2026-11-09";
  src = fetchFromGitHub {
    owner = "manic-systems";
    repo = "tack";
    rev = "f59bc3e6679df14d402e40bf895cc2533bae4ca2";
    hash = "sha256-ZK5sfTsvSo9VYEi8mAVtfu5FUFvMYoGMn6+CYzS1pPU=";
  };

  __structuredAttrs = true;

  cargoHash = "sha256-edYigZ2aQYbxmHuuIiQo9lMTsu3YFgaRySgVbbSVY0I=";

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
