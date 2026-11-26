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
  version = "1.0.1-unstable-2026-11-26";
  src = fetchFromGitHub {
    owner = "manic-systems";
    repo = "tack";
    rev = "147cec2879505729dbcf2d8ff9848be19b6f7094";
    hash = "sha256-qGjfI0mOgZ1WXjocPeDCL0WqjWy2v0/VyMgYqwfmf6k=";
  };

  __structuredAttrs = true;

  cargoHash = "sha256-KejNCcCdV603DtUQGO1gzEslSBW+oBrbrTfCr+tnDjc=";

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
