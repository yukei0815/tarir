let
  tarirfiles = import ./pkgs.nix;
  tarirpkgs = import ./default.nix { };

  # Group packages into seperate actions matrix jobs
  groups = {
    eden-nightly = { inherit (tarirpkgs) eden-nightly; };
    eden-nightly-zen4-pgo = { inherit (tarirpkgs) eden-nightly-zen4-pgo; };
  };

  jobs = groups // {
    main = builtins.removeAttrs tarirpkgs (
      builtins.concatMap builtins.attrNames (builtins.attrValues groups)
    );
  };

  readPkg =
    path:
    builtins.readFile (
      if (builtins.readFileType path == "directory") then path + /default.nix else path
    );

  # Cursed, but saves a nixpkgs download in CI
  hasUpdateScript = src: builtins.length (builtins.split "updateScript" src) > 1;

  packagesToUpdate = builtins.filter (name: hasUpdateScript (readPkg tarirfiles.${name})) (
    builtins.attrNames tarirfiles
  );
in
{
  inherit packagesToUpdate jobs;

}
