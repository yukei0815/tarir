{
  # Let's nix-update use pinned pkgs from flake without including --flake in every updateScript.
  pkgs ?
    let
      lock = builtins.fromJSON (builtins.readFile ./flake.lock);
    in
    import (builtins.fetchTree lock.nodes.nixpkgs.locked) { },
}:
import ./pkgs.nix { inherit pkgs; }
