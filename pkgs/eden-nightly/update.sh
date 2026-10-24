#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update common-updater-scripts jq curl

set -eu -o pipefail

# Follow eden-ci nightly releases rather than every commit,
# shortrev gotten from the tag timestamp>.<short rev>
api=https://git.eden-emu.dev/api/v1/repos
tag=$(curl -sSf "$api/eden-ci/nightly/releases/latest" | jq -r .tag_name)
commit=$(curl -sSf "$api/eden-emu/eden/git/commits/${tag#*.}?stat=false&verification=false&files=false")
base=$(curl -sSf "$api/eden-emu/eden/tags?limit=1" | jq -r '.[0].name | ltrimstr("v")')


update-source-version eden-nightly \
  "$base-unstable-$(jq -r '.commit.committer.date[:10]' <<<"$commit")" \
  --rev="$(jq -r .sha <<<"$commit")"


dir=$(dirname "$(nix eval --raw -f . "$UPDATE_NIX_ATTR_PATH.meta.position")")
src=$(nix build --no-link --print-out-paths .#eden-nightly.src)

# Follow eden's pin, tags are DDMMYY but set version as YY.MM.DD
nix-update eden-nightly.nx_tzdb \
  --version="$(jq -r '.tzdb.version | "\(.[4:6]).\(.[2:4]).\(.[0:2])"' "$src/cpmfile.json")"

profdata=$(curl -sSf https://api.github.com/repos/Eden-CI/PGO/releases/latest \
  | jq '{version: .tag_name, hash: (.assets[] | select(.name == "eden.profdata") | .digest | ltrimstr("sha256:"))}')

jq --argjson profdata "$profdata" '{reshade, zbic, $profdata}' "$src/cpmfile.json" > "$dir/pins.json"
