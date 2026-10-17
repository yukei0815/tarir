let
  tarirfiles = import ./pkgs.nix;

  # Cursed, but saves a nixpkgs download in CI
  hasUpdateScript =
    path:
    let
      file = if (builtins.readFileType path == "directory") then path + /default.nix else path;
      src = builtins.readFile file;
    in
    builtins.length (builtins.split "updateScript" src) > 1;
in
{
  packagesToUpdate = builtins.filter (name: hasUpdateScript tarirfiles.${name}) (
    builtins.attrNames tarirfiles
  );
}
