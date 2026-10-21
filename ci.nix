let
  tarirfiles = import ./pkgs.nix;
  readPkg =
    path:
    builtins.readFile (
      if (builtins.readFileType path == "directory") then path + /default.nix else path
    );

  # Cursed, but saves a nixpkgs download in CI
  hasUpdateScript = src: builtins.length (builtins.split "updateScript" src) > 1;
in
{
  packagesToUpdate = builtins.filter (name: hasUpdateScript (readPkg tarirfiles.${name})) (
    builtins.attrNames tarirfiles
  );
}
