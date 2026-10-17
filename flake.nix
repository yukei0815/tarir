{
  inputs.nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
  outputs =
    { nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      allPkgs = fn: lib.genAttrs lib.systems.flakeExposed (system: fn nixpkgs.legacyPackages.${system});
    in
    {
      packages = allPkgs (pkgs: import ./default.nix { inherit pkgs; });
      overlays.default = import ./overlay.nix;
    };
}
