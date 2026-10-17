final: prev: import ./default.nix { pkgs = final; inherit (prev) lib; }
