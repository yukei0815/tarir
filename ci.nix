let
  tarirfiles = import ./pkgs.nix;

  # Minimum intereval between git package updates
  # Allows to delay git package updates to prevent excessive daily builds/cache
  # In days how long to delay update since the last pinned git commit
  defaultInterval = 3;
  # Per package
  intervals = { };

  readPkg =
    path:
    builtins.readFile (
      if (builtins.readFileType path == "directory") then path + /default.nix else path
    );

  # Cursed, but saves a nixpkgs download in CI
  hasUpdateScript = src: builtins.length (builtins.split "updateScript" src) > 1;

  # Somehow even more cursed (gj claude)
  # Should really remove the check or perform it in CI/script (~_~メ)
  # https://howardhinnant.github.io/date_algorithms.html#days_from_civil
  daysFromCivil =
    y': m: d:
    let
      y = if m <= 2 then y' - 1 else y';
      era = builtins.div y 400;
      yoe = y - era * 400;
      doy = builtins.div (153 * (if m > 2 then m - 3 else m + 9) + 2) 5 + d - 1;
      doe = yoe * 365 + builtins.div yoe 4 - builtins.div yoe 100 + doy;
    in
    era * 146097 + doe - 719468;

  today = builtins.div builtins.currentTime 86400;

  # Age in days of the pinned commit
  pinnedAge =
    src:
    let
      m = builtins.filter builtins.isList (
        builtins.split "-unstable-([0-9]{4})-0?([0-9]{1,2})-0?([0-9]{1,2})" src
      );
      date = map builtins.fromJSON (builtins.head m);
    in
    if m == [ ] then null else today - builtins.foldl' (f: f) daysFromCivil date;

  isDue =
    name: src:
    let
      age = pinnedAge src;
    in
    age == null || age >= intervals.${name} or defaultInterval;
in
{
  packagesToUpdate = builtins.filter (
    name:
    let
      src = readPkg tarirfiles.${name};
    in
    hasUpdateScript src && isDue name src
  ) (builtins.attrNames tarirfiles);
}
