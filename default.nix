{
  # Let's nix-update use pinned pkgs from flake without including --flake in every updateScript.
  # as the inner updateScript uses default.nix if --flake is not specified.
  pkgs ?
    let
      lock = builtins.fromJSON (builtins.readFile ./flake.lock);
    in
    import (builtins.fetchTree lock.nodes.nixpkgs.locked) { },
  lib ? pkgs.lib,
}:
let
  # Includes our own packages so they can depend on each other outside the overlay too.
  callPackage = lib.callPackageWith (
    pkgs
    // self
    // {
      nix-update-script = pkgs.nix-update-script.override {
        nix-update = pkgs.lixPackageSets.lix_2_95.nix-update;
      };
    }
  );

  self = builtins.mapAttrs (_: path: callPackage path { }) (import ./pkgs.nix);
in
self
