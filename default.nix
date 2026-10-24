{
  pkgs ?
    let
      lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
    in
    import (builtins.fetchTarball {
      inherit (lock) url;
      sha256 = lock.narHash;
    }) { },
  lib ? pkgs.lib,
}:
lib.fix (
  self:
  let
    callPackage = pkgs.newScope (
      self
      // {
        nix-update-script = pkgs.nix-update-script.override {
          nix-update = pkgs.lixPackageSets.lix_2_96.nix-update;
        };
      }
    );
    auto = builtins.mapAttrs (_: path: callPackage path { }) (import ./pkgs.nix);
  in
  auto
  // ({

  })
)
