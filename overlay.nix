final: prev: import ./pkgs.nix { pkgs = final; inherit (prev) lib; }
