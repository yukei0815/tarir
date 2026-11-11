#!/usr/bin/env nix-shell
#!nix-shell -i bash -p git jq

set -euo pipefail
shopt -s inherit_errexit

# Usage: update.sh <variant>, writes <variant>.json
#   latest  newest release
#   rc      newest release or rc
#   X.Y     the X.Y kernel line
variant=${1:?usage: update.sh <latest|rc|X.Y>}
json=$(dirname "$(nix eval --raw -f . linux-salkim-latest.meta.position)")/$variant.json

kernel_repo=nanomatters/kernel-salkim
# Follow the maintainer's Fedora specs: they pin the kernel commit, mark rcs and list extra patches
spec_repo=nanomatters/linux-salkim
checkout=$(mktemp -d)
trap 'rm -rf "$checkout"' EXIT
git clone -q "https://github.com/$spec_repo" "$checkout"

mapfile -t specs < <(printf '%s\n' "$checkout"/linux-salkim-*/kernel-salkim.spec | sort -V)
case $variant in
  # grep fails when every spec is an rc, leave that to the check below
  latest) spec=$(grep -L '^Release:.*rc' "${specs[@]}" | tail -n1) || true ;;
  rc) spec=${specs[-1]} ;;
  *) spec=$checkout/linux-salkim-$variant/kernel-salkim.spec ;;
esac

if [[ ! -f $spec ]]; then
  broken=$(jq --arg error "no spec for $variant in $spec_repo" '.hash = "" | .error = $error' "$json")
  echo "$broken" >"$json"
  exit 0
fi
dir=$(basename "$(dirname "$spec")")

field() { awk -v key="$1:" '$1 == key {print $2; exit}' "$spec"; }
release=$(field Release | sed 's/%{?dist}//')
version=$(field Version)-$release
commit=$(awk '$2 == "kernel_commit" {print $3}' "$spec")

# What `make kernelrelease` prints: padded to x.y.z, plus the rc from the Makefile's EXTRAVERSION
modDirVersion=$(field Version)
[[ $modDirVersion == *.*.* ]] || modDirVersion+=.0
if [[ $release =~ rc[0-9]+ ]]; then modDirVersion+=-${BASH_REMATCH[0]}; fi

nixpkgs=$(nix eval --raw --inputs-from . nixpkgs#path)


# {hash: "", error} if it cant be fetched
prefetch() {
  local log hash
  log=$(nix build --no-link --impure --expr "with import $nixpkgs { }; $1" 2>&1) || true
  hash=$(awk '$1 == "got:" {print $2}' <<<"$log")
  if [[ -n $hash ]]; then
    jq -n --arg hash "$hash" '{$hash}'
  else
    echo "$log" >&2
    jq -n --arg error "$(grep -i error <<<"$log" | tail -n1 | sed 's/^[> ]*//')" '{hash: "", $error}'
  fi
}

# Only download the kernel when the commit changed
if [[ -f $json ]] && jq -e --arg rev "$commit" '.rev == $rev and .hash != ""' "$json" >/dev/null; then
  src=$(jq '{hash}' "$json")
else
  src=$(prefetch "fetchFromGitHub { owner = \"${kernel_repo%/*}\"; repo = \"${kernel_repo#*/}\"; rev = \"$commit\"; hash = \"\"; }")
fi

# Pin local patches to the last commit touching them, so the url only changes with the patch
patch_url() {
  if [[ $1 == https://* ]]; then
    echo "$1"
  else
    local rev
    rev=$(git -C "$checkout" log -1 --format=%H -- "$dir/$1")
    echo "https://raw.githubusercontent.com/$spec_repo/$rev/$dir/$1"
  fi
}

patches=$(awk '$1 ~ /^Patch[0-9]+:$/ {print $2}' "$spec" | while read -r patch; do
  url=$(patch_url "$patch")
  prefetch "fetchpatch2 { url = \"$url\"; hash = \"\"; }" | jq --arg url "$url" '{$url} + .'
done | jq -s .)

jq -n \
  --arg version "$version" \
  --arg modDirVersion "$modDirVersion" \
  --arg rev "$commit" \
  --argjson src "$src" \
  --argjson patches "$patches" \
  '{$version, $modDirVersion, $rev} + $src + {$patches}' >"$json"
