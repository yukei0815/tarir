{
  # CI entrypoint
  pkgs ?
    let
      lock = builtins.fromJSON (builtins.readFile ./flake.lock);
    in
    import (builtins.fetchTree lock.nodes.nixpkgs.locked) { config.allowUnfree = true; },
}:
let
  tarir = import ./pkgs.nix { inherit pkgs; };
  inherit (pkgs) lib;

  excludedProvenance = with lib.sourceTypes; [
    binaryNativeCode
    binaryBytecode
    binaryFirmware
    obfuscatedCode
  ];

  licensesOf = pkg: lib.toList (pkg.meta.license or [ ]);

  isUnfreeNonRedistributable =
    pkg:
    lib.any (l: lib.isAttrs l && (l.free or true) == false && (l.redistributable or false) == false) (
      licensesOf pkg
    );

  hasExcludedProvenance =
    pkg: lib.any (s: lib.elem s excludedProvenance) (lib.toList (pkg.meta.sourceProvenance or [ ]));

  status =
    pkg:
    if !(lib.isDerivation pkg) then
      "skip"
    else if (pkg.meta.broken or false) == true then
      "broken"
    else if hasExcludedProvenance pkg || isUnfreeNonRedistributable pkg then
      "buildOnly"
    else
      "buildAndCache";

  byStatus = s: lib.filterAttrs (_: pkg: status pkg == s) tarir;

  buildAndCache = byStatus "buildAndCache";
  buildOnly = byStatus "buildOnly";
  # broken = byStatus "broken";
in
{
  inherit buildAndCache buildOnly;
}
