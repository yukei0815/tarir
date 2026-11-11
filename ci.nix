let
  tarirpkgs = import ./default.nix { };

  # Group packages into seperate actions matrix jobs
  groups = {
    eden-nightly = { inherit (tarirpkgs) eden-nightly; };
    eden-nightly-zen4-pgo = { inherit (tarirpkgs) eden-nightly-zen4-pgo; };
    woodpecker = { };
  };

  jobs = groups // {
    main = builtins.removeAttrs tarirpkgs (
      builtins.concatMap builtins.attrNames (builtins.attrValues groups)
    );
  };

  variants = builtins.attrNames (import ./pkgs.nix { }).variants;

  packagesToUpdate = builtins.filter (
    name: !(builtins.elem name variants) && tarirpkgs.${name} ? updateScript
  ) (builtins.attrNames tarirpkgs);
in
{
  inherit packagesToUpdate jobs;

}
