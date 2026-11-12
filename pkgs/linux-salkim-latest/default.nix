{
  lib,
  buildLinux,
  fetchFromGitHub,
  fetchpatch2,
  linux_latest,
  # latest, rc or a kernel line like 7.3, see update.sh
  variant ? "latest",
  ...
}@args:

let
  pin = lib.importJSON ./${variant}.json;
in
(buildLinux (
  args
  // rec {
    pname = "linux-salkim";
    inherit (pin) version modDirVersion;

    src = fetchFromGitHub {
      owner = "nanomatters";
      repo = "kernel-salkim";
      inherit (pin) rev hash;
    };

    kernelPatches =
      linux_latest.kernelPatches
      ++ (args.kernelPatches or [ ])
      ++ map (p: {
        name = baseNameOf p.url;
        patch = fetchpatch2 { inherit (p) url hash; };
      }) pin.patches;

    extraPassthru.updateScript = [
      ./update.sh
      variant
    ];

    extraMeta = {
      branch = lib.versions.majorMinor version;
      description = "Linux stable kernel with amdgpu fixes and backports";
      homepage = "https://github.com/nanomatters/kernel-salkim";
      maintainers = [ { name = "yukei"; } ];
    };
  }
  // (args.argsOverride or { })
)).overrideAttrs
  (old: {
    # Because of buidLinux being strange
    # unsafeGetAttrPos will return the incorrect file location for src and version
    # So nix-update can't function properly
    # Workaround: override version and src so unsafeGetAttrPos points to this file
    inherit (old) src;
    passthru = old.passthru // {
      inherit (old) version;
    };
  })
