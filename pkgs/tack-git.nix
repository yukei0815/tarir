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
  version = "1.0.1-unstable-2026-11-12";
  src = fetchFromGitHub {
    owner = "manic-systems";
    repo = "tack";
    rev = "1d1bbe2a27c416458be61a941a6228afea534e6e";
    hash = "sha256-KXFPNN+Js56ATlxNR40ttj1Azp866HSbQMquq5zt5Dc=";
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
