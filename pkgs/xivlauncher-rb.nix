# Added extraCompatPackages option to allow proton use
# without symlinking into ~/
# Split into two packages
# so overriding extraCompatPackages doesn't rebuild from source
{
  lib,
  symlinkJoin,
  makeWrapper,
  linkFarm,
  steam,
  umu-launcher,
  xivlauncher-rb-unwrapped,
  extraCompatPackages ? [ ],
}:
let
  compatToolsDir = linkFarm "steam-compat-tools" (
    map (pkg: {
      name = "share/steam/compatibilitytools.d/${pkg.pname}";
      path = lib.getOutput "steamcompattool" pkg;
    }) extraCompatPackages
  );

  umu = umu-launcher.override {
    extraPkgs = _: lib.optional (extraCompatPackages != [ ]) compatToolsDir;
  };

  steam-run =
    (steam.override {
      extraPkgs =
        pkgs:
        [
          pkgs.libunwind
          umu
        ]
        ++ lib.optional (extraCompatPackages != [ ]) compatToolsDir;
      extraProfile = ''
        unset TZ
      '';
    }).run-free;
in
symlinkJoin {
  pname = "xivlauncher-rb";
  inherit (xivlauncher-rb-unwrapped) version;

  paths = [ xivlauncher-rb-unwrapped ];
  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    rm $out/bin/XIVLauncher.Core
    makeWrapper ${lib.getExe steam-run} $out/bin/XIVLauncher.Core \
      --add-flags ${lib.getExe xivlauncher-rb-unwrapped}
  '';

  passthru.unwrapped = xivlauncher-rb-unwrapped;

  inherit (xivlauncher-rb-unwrapped) meta;
}
