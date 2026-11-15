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
  version = "1.0.1-unstable-2026-11-15";
  src = fetchFromGitHub {
    owner = "manic-systems";
    repo = "tack";
    rev = "4bb81b579e2072b02f8a7a56e9da317e6faf5407";
    hash = "sha256-PSwYLv40mPN9//mGLA+5Q3YUPfS16dMTrd4BARJhCuo=";
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
