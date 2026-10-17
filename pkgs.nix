builtins.listToAttrs (
  map (file: {
    name =
      let
        m = builtins.match "(.*)\\.nix" file;
      in
      if m == null then file else builtins.head m;
    value = ./pkgs + "/${file}";
  }) (builtins.attrNames (builtins.readDir ./pkgs))
)
