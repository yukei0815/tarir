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
  version = "1.0.1-unstable-2026-11-16";
  src = fetchFromGitHub {
    owner = "manic-systems";
    repo = "tack";
    rev = "ec2c5be358b8c2cfe0e7674b60e8feccb33d7307";
    hash = "sha256-Tz93VI/CWOYIrQtdyCxo+TEWnrZPtZ0qd4DsKVdFaBs=";
  };

  __structuredAttrs = true;

  cargoHash = "sha256-U8PVSnkQSmv+CZCJbwg3PltrJFXg1QKPX/7ABcAbBsA=";

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
