# Tarir

`tarir` is my personal Nix package repo. I package things I'm missing from nixpkgs. Mostly forks and nightly/unstable packages. Feel free to use but no stability guaranteed :)

## Package list

| Package | Description |
| --- | --- |
| [`niri-urayde`](https://github.com/urayde/niri) | niri compositor fork with extra features such as `tearing-protocol` and `explicit-sync` |
| [`xivlauncher-rb`](https://github.com/rankynbass/XIVLauncher.Core) | `xivlauncher` fork with many extra linux patches. Package can add proton into the environment. `.override { extraCompatPackages = [ pkgs.proton-ge-bin ]; }` |
| [`eden-nightly`](https://git.eden-emu.dev/eden-ci/nightly/releases) | `eden` emulator nightly releases with optional support for PGO and march built optimization |
| `eden-nightly-zen4-pgo` | `eden` nightly built for zen4 with PGO |


## Usage

```nix
# flake input
inputs.tarir.url = "github:yukei0815/tarir";

# then either
tarir.packages.${system}.<name>
# or with overlay: (May cause cache misses)
nixpkgs.overlays = [ tarir.overlays.default ];
```

> [!NOTE]
> The cache is built against tarir's nixpkgs, updated daily. With `inputs.nixpkgs.follows` or the overlay, cache hits depend on your nixpkgs being up to date.

Without flakes I recommended to use an input pinning tool such as `npins`, `lon`, `unflake`, `tack`. To use unpinned:

```nix
tarir-src = fetchTarball "https://github.com/yukei0815/tarir/archive/main.tar.gz";

# then
(import tarir-src { }).<name>
# or using own pkgs (may cause cache misses)
(import tarir-src { inherit pkgs; }).<name>

# with overlay: (may cause cache misses)
nixpkgs.overlays = [ (import "${tarir-src}/overlay.nix") ];
```

## Binary cache

> [!WARNING]
> Use at own risk - binary caches are a security risk if you don't fully trust the operator!

Packages are cached against `nixos-unstable`

```nix
nix.settings = {
  extra-substituters = [ "https://cache.yukei.moe" ];
  extra-trusted-public-keys = [ "cache.yukei.moe-1:nKiu5HmD5avk8o3L7XxUjIWkmb5KQXNh+/MxEfhjoQc=" ];
};
```
