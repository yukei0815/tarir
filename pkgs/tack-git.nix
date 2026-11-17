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
  version = "1.0.1-unstable-2026-11-17";
  src = fetchFromGitHub {
    owner = "manic-systems";
    repo = "tack";
    rev = "bad78453288bfb5d890af856fa2429979e2b944c";
    hash = "sha256-Jn+PT5iYnKcttgR5Rc6oWLNxhFGzyBY3/P3sgvqcQDU=";
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
