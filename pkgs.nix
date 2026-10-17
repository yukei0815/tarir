{ pkgs, lib ? pkgs.lib }:
let
  callPackage = lib.callPackageWith (
    pkgs
    // {
      nix-update-script = pkgs.nix-update-script.override {
        nix-update = pkgs.lixPackageSets.lix_2_95.nix-update;
      };
    }
  );
in
lib.mapAttrs' (file: _: {
  name = (lib.removeSuffix ".nix" file);
  value = callPackage (./pkgs + "/${file}") { };
}) (builtins.readDir ./pkgs)
